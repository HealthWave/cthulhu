module Cthulhu
  class Queue
    attr_accessor :type, :name, :queue, :exchange, :block
    def initialize(type:, block:, topic: nil)
      @type = type
      @block = block
      @topic = topic
    end

    def start
      case type
      when 'status'
      when 'topic'
        raise "Topic queue requires a topic." unless topic
        start_topic
      when 'fanout'
        start_fanout
      else
      end
    end

    def start_topic
      exchange = Cthulhu.channel.topic("topic", auto_delete: false)
      name = "#{Cthulhu::Application.queue_name}.topic"
      queue = Cthulhu.channel.queue(name, auto_delete: false, durable: true, exclusive: false)
      queue.bind(exchange, routing_key: topic)

    end

    def start_fanout
      name = "#{Cthulhu::Application.queue_name}.broadcast"
      queue = Cthulhu.channel.queue(queue_name, auto_delete: false, durable: true)
      exchange = Cthulhu.channel.fanout(exchange_type, durable: true)
      queue.bind(exchange)
      queue.subscribe(block: block, manual_ack: true) do |delivery_info, properties, payload|

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

    # parsing incoming messages
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
  end
end
