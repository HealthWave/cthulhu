require 'ostruct'

module Cthulhu
  class Application

    def self.logger
      Cthulhu.logger
    end

    def self.start(block: true)
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
      Cthulhu::Queue.new(type: 'fanout').start
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
      message = Cthulhu::IncomingMessage.new(delivery_info, properties, payload)
      if message.valid?
        # set the log format
        logger.formatter = proc do |severity, datetime, progname, m|
          "#{message.timestamp} #{Cthulhu::Application.name} #{message.uuid} #{message.from} #{m}\n"
        end
        result, response = handler_exists?(message)
        if result
          return call_handler_for(message)
        elsif Cthulhu.global_route.nil?
          logger.error response
          logger.info "Valid routes are: #{Cthulhu.routes}"
          return "ignore!"
        else
          return call_global_route(message)
        end
      else
        return 'ignore!'
      end

    end

    def self.handler_exists?(message)

      class_name = Cthulhu.routes[ message.subject ]
      if Cthulhu.routes.nil? || class_name.nil?
        return [false, "No route matches subject #{message.subject}"]
      end
      klass = Object.const_get class_name
      if klass.method_defined?( message.action )
        return [true, class_name]
      else
        return [false, "Action #{message.action} is not defined on handler #{class_name}"]
      end
    rescue NameError => e
      return [false, e]
    end

    def self.call_global_route(message)
      klass = Object.const_get Cthulhu.global_route[:to]
      klass.new(message).handle_action(Cthulhu.global_route[:action])
    rescue NameError => e
      raise MissingGlobalRouteError.new("#{Cthulhu.global_route[:to]} class is missing or not defined, global routes must be defined.")
    end

    def self.call_handler_for(message)
      class_name = Cthulhu.routes[message.subject]
      method_name = message.action
      logger.info "Routing subject '#{message.subject}' to #{class_name}##{method_name}"
      klass = Object.const_get class_name
      klass.new(message).handle_action(method_name)
    end
  end
end
