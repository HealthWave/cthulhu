module Cthulhu
  class Queue
    attr_accessor :type, :block, :logger, :manual_ack
    def initialize(type, block:, manual_ack:)
      @type = type
      @block = block
      @manual_ack = manual_ack
      @logger = ::Cthulhu.logger.clone
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
      queue.subscribe(consumer_tag: Cthulhu.consumer_tag, block: self.block, manual_ack: manual_ack) do |delivery_info, properties, payload|
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
          logger.formatter = proc do |severity, datetime, progname, m|
            "#{datetime.to_f} #{severity} SENT_AT=#{incoming_message.timestamp.to_i} GROUP_ID=#{incoming_message.group_id} FROM=#{incoming_message.sender_fqan} TO=#{incoming_message.to} MESSAGE_ID=#{incoming_message.message_id} CORRELATION_ID=#{incoming_message.correlation_id|| "nil"} | #{m}\n"
          end
          logger.error "Handler actions must return ack!, ignore! or requeue!"
        end
      end
    end

    def start_fanout

    end


  end
end
