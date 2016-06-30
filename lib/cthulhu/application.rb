module Cthulhu
  class Application
    @@name = nil
    @@logger = nil
    @@queue_name = nil
    @@dry_run = false
    def self.logger=(logger)
      raise "Invalid logger" unless logger.instance_of? Logger
      @@logger = logger
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
      puts "Cthulhu loaded. Press CTRL+C to QUIT."

      ############################
      ##### DIRECT QUEUE #########
      ############################
      x = Cthulhu.channel.direct("#{Cthulhu::Application.queue_name}.direct")
      q = Cthulhu.channel.queue("", auto_delete: true, exclusive: true).bind(x, routing_key: "rpc")
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
      ##### BROADCAST QUEUE ######
      ############################
      queue_name = "#{Cthulhu::Application.queue_name}.broadcast"
      queue = Cthulhu.channel.queue(queue_name, auto_delete: false, durable: true)
      exchange = Cthulhu.channel.fanout(exchange_type, durable: true)
      queue.bind(exchange)
      queue.subscribe(consumer_tag: Cthulhu::Application.name, block: block, manual_ack: true) do |delivery_info, properties, payload|
        case parse(delivery_info, properties, payload)
        when "ack!"
          # acknowledge the message and remove from queue
          Cthulhu.channel.ack(delivery_info.delivery_tag, false)
        when "ignore!"
          # reject the message but dont add it back to the queue
          Cthulhu.channel.reject(delivery_info.delivery_tag)
        when "requeue!"
          # reject the message and requeue
          Cthulhu.channel.reject(delivery_info.delivery_tag, true)
        else
          logger.error "Handler actions must return ack!, ignore! or requeue!"
        end
      end
    end
    def self.parse(delivery_info, properties, payload)
      headers = properties.headers
      message = JSON.parse payload, symbolize_names: true
      return 'ignore!' unless valid?(properties, message)

      # set the log format
      logger.formatter = proc do |severity, datetime, progname, m|
        "#{properties.timestamp || DateTime.now} #{properties.message_id} #{properties.headers['from']} #{m}\n"
      end

      logger.info "Got message - headers: #{headers} - payload: #{message}"
      logger.info "Message is valid"

      handler = handler_exists?(properties, message)
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
                message.is_a?(Hash) &&
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
        return false
      else
        return true
      end
    end

    def self.handler_exists?(properties, message)
      method_name = properties.headers["action"].downcase
      class_name = Cthulhu.routes[properties.headers["subject"]]

      if !class_name || !Object.const_defined?(class_name)
        return false
      end

      klass = Object.const_get class_name
      return klass.method_defined?(method_name)
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
