module Cthulhu
  class Queue
    attr_accessor :type, :block
    def initialize(type, block: )
      @type = type
      @block = block
    end

    def start
      case type
      when :status
      when :inbox
        start_inbox
      when :fanout
      else
      end
    end

    def start_inbox
      queue = Cthulhu.channel.queue(Cthulhu.inbox_exchange_name, auto_delete: false, durable: true, exclusive: false)
      queue.bind(Cthulhu.inbox_exchange)
      queue.subscribe(consumer_tag: Cthulhu.consumer_tag, block: self.block, manual_ack: true) do |delivery_info, properties, payload|
        incoming_message = Cthulhu::IncomingMessage.new(delivery_info, properties, payload)
        case incoming_message.call_handler
        when :ack
          # acknowledge the message and remove from queue
          Cthulhu.channel.ack(delivery_info.delivery_tag, false)
        when :ignore
          # reject the message but dont add it back to the queue
          Cthulhu.channel.reject(delivery_info.delivery_tag)
        when :requeue
          # reject the message and requeue
          Cthulhu.channel.reject(delivery_info.delivery_tag, true)
        else
          logger.error "Handler actions must return ack!, ignore! or requeue!"
        end
      end
    end

    def start_fanout

    end


  end
end
