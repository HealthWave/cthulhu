require 'securerandom'

module Cthulhu
  class Message
    def self.broadcast message
      validate(message)
      if Cthulhu::Application.dry_run
        puts "Dry run mode enabled. Messages will not be sent."
        return
      end
      exchange = Cthulhu.channel.fanout("broadcast", durable: true)

      payload = message[:payload].to_json
      options = {
        message_id: SecureRandom.uuid,
        timestamp: Time.now.to_i,
        headers: {
          from: Cthulhu::Application.name,
          subject: message[:subject],
          action: message[:action]
        }
      }
      exchange.publish(payload, options)
    end

    # def self.direct_message payload
    #   exchange = Cthulhu.channel.default_exchange
    #   message = build_message(payload)
    #
    #   exchange.publish(message, routing_key: Cthulhu::Application.name)
    # end
    #
    # def self.build_message payload
    #   validate(payload)
    #   payload.merge!(uuid: SecureRandom.uuid,
    #                  from: Cthulhu::Application.name,
    #                  timestamp: DateTime.now
    #                  ).to_json
    # end

    def self.validate message
      raise "Message must have a subject" if message[:subject].blank?
      raise "Message must have an action" if message[:action].blank?
      raise "Message must have a message (even if it is empty)" if message[:payload].empty?
      true
    end
  end
end
