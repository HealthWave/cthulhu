require 'ostruct'

module Cthulhu
  class Application
    @@name = nil
    @@logger = nil
    @@queue_name = nil
    @@dry_run = false
    def self.logger=(l)
      raise "Invalid logger. Expected Logger but got #{logger.class.name}" unless l.instance_of?(Logger) || l.instance_of?(ActiveSupport::Logger)
      @@logger = l
    end
    def self.logger
      @@logger
    end
    def self.name
      @@name
    end
    def self.name=(name)
      @@name = name
    end
    def self.queue_name
      @@queue_name
    end
    def self.queue_name=(queue_name)
      @@queue_name = queue_name
    end
    def self.dry_run=(state)
      @@dry_run = state
    end
    def self.dry_run
      @@dry_run
    end
    def self.start(block: true, exchange_type: 'broadcast')
      raise "CTHULHU_ENV constant is not set." unless ENV['CTHULHU_ENV']
      return if ENV['CONSOLE'] == '1'
      puts "Starting #{Cthulhu::Application.name} on queue #{Cthulhu::Application.queue_name}, enviroment #{ENV['CTHULHU_ENV']}."
      puts "Cthulhu #{Gem.loaded_specs["cthulhu"].version} loaded. Press CTRL+C to QUIT."

      ############################
      ##### DIRECT QUEUE #########
      ############################
      x = Cthulhu.channel.direct("#{Cthulhu::Application.queue_name}.direct")
      q = Cthulhu.channel.queue("#{Cthulhu::Application.queue_name}.direct", auto_delete: true, exclusive: false).bind(x, routing_key: "rpc")
      q.subscribe do |delivery_info, properties, payload|
        reply_tox = Cthulhu.channel.direct(properties.headers["reply_to"])
        begin
          message = eval(payload).to_json
          reply_tox.publish(message, routing_key: "rpc")
        rescue
          reply_tox.publish("null", routing_key: "rpc")
        end
      end
      ############################
      ##### STATUS QUEUE ######
      ############################
      $peers = {}
      status_queue_name = "#{Cthulhu::Application.queue_name}.status"
      status_queue = Cthulhu.channel.queue(status_queue_name, auto_delete: false, durable: true)
      status_exchange = Cthulhu.channel.fanout('status', durable: true)
      status_queue.bind(status_exchange)
      status_queue.subscribe(block: false, manual_ack: false) do |delivery_info, properties, payload|
        message = JSON.parse(payload)
        if properties["headers"]
          $peers[properties["headers"]["from"]] = message
        end
      end
      ############################
      ##### BROADCAST QUEUE ######
      ############################
      queue_name = "#{Cthulhu::Application.queue_name}.broadcast"
      queue = Cthulhu.channel.queue(queue_name, auto_delete: false, durable: true)
      exchange = Cthulhu.channel.fanout(exchange_type, durable: true)
      queue.bind(exchange)
      queue.subscribe(block: block, manual_ack: true) do |delivery_info, properties, payload|

        case parse(delivery_info, properties, payload)
        when "ack!"
          # acknowledge the message and remove from queue
          Cthulhu.channel.ack(delivery_info.delivery_tag, false)
        when "ignore!"
          logger.info Cthulhu.routes
          # reject the message but dont add it back to the queue
          Cthulhu.channel.reject(delivery_info.delivery_tag)
        when "requeue!"
          # reject the message and requeue
          Cthulhu.channel.reject(delivery_info.delivery_tag, true)
        else
          logger.error "Handler actions must return ack!, ignore! or requeue!"
        end
      end
      ####### publish I am here
      options = {
        message_id: SecureRandom.uuid,
        timestamp: Time.now.to_i,
        headers: {
          from: Cthulhu::Application.name
        }
      }
      status_exchange.publish((Cthulhu.routes || {}).to_json, options)
      # Start timer
      timer = Thread.new do
        sleep 60
        if Cthulhu.routes
          logger.info "Publishing routes #{Cthulhu.routes}"
          status_exchange.publish(Cthulhu.routes.to_json, options)
        end
      end
    end
    def self.parse(delivery_info, properties, payload)
      headers = properties.headers
      # ignore messages sent by myself
      # return "ignore!" if headers["from"] == Cthulhu::Application.name
      message = JSON.parse payload, object_class: OpenStruct
      return 'ignore!' unless valid?(properties, message)

      # set the log format
      logger.formatter = proc do |severity, datetime, progname, m|
        "#{properties.timestamp || DateTime.now} #{properties.message_id} #{properties.headers['from']} #{m}\n"
      end

      logger.info "Got message - headers: #{headers} - payload: #{message}"
      logger.info "Message is valid"

      handler = handler_exists?(headers, message)
      unless handler
        logger.error "No route matches subject '#{headers["subject"]}'"
        return "ignore!"
      end

      return call_handler_for(properties, message)

    end
    def self.valid?(properties, message)
      # carefully inspect the message
      headers = properties.headers
      unless  (
                properties.message_id.is_a?(String) &&
                headers["subject"].is_a?(String) &&
                headers["action"].is_a?(String) &&
                message.is_a?(OpenStruct) &&
                properties.timestamp.is_a?(Time) &&
                headers["from"].is_a?(String)
              )
        logger.formatter = proc do |severity, datetime, progname, m|
          "E -- #{datetime} ERROR #{m}\n"
        end
        logger.error "Invalid message: #{properties.inspect} - #{message}"
        return false
      end
      if headers["subject"].blank? || headers["action"].blank? || headers["from"].blank? || message.empty?
        logger.error "Invalid message: #{headers.inspect} - #{message}"
        return false
      else
        return true
      end
    end

    def self.handler_exists?(headers, message)
      class_name = Cthulhu.routes[ headers["subject"] ]
      if Cthulhu.routes.nil? || class_name.nil?
        return false
      end
      klass = Object.const_get class_name

      return false unless klass.method_defined?( headers["action"].downcase )
      return class_name
    rescue NameError => e
      return false
    end

    def self.call_handler_for(properties, message)
      headers = properties.headers
      class_name = Cthulhu.routes[headers["subject"]]
      method_name = headers["action"].downcase
      logger.info "Routing subject '#{headers["subject"]}' to #{class_name}##{method_name}"
      klass = Object.const_get class_name
      klass.new(properties, message).handle_action(method_name)
    end
  end
end
