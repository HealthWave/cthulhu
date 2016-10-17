require 'securerandom'
require 'json'
module Cthulhu
  class IncomingMessage
    attr_accessor :payload, :headers, :options, :from, :delivery_info,
                  :properties, :message_id, :timestamp, :logger, :content_type,
                  :raw_payload
    def initialize(delivery_info, properties, payload)
      @logger = Cthulhu.logger.clone
      @delivery_info = delivery_info
      @properties = properties
      @headers = @properties.headers
      @content_type = @headers["content-type"]
      @raw_payload = payload
      case @content_type
      when 'application/json'
        @payload = JSON.parse payload
      when 'object/marshal-dump'
        @payload = Marshal.load(payload)
      else
        @payload = payload
      end
      @options = @headers["options"]
      @from = @headers["from"]
      @message_id = properties.message_id
      @timestamp = properties.timestamp
    end

    def valid?
      # carefully inspect the message
      if  (
              message_id.is_a?(String) && !message_id.blank?
              payload.is_a?(Hash) &&
              timestamp.is_a?(Time) &&
              from.is_a?(String) && !from.blank?
            )
      logger.formatter = proc do |severity, datetime, progname, m|
        "#{timestamp} #{Cthulhu::Application.name} #{uuid} #{from} #{m}\n"
      end
      logger.info "Valid message: #{self.to_hash}"
      return true
      else
        logger.formatter = proc do |severity, datetime, progname, m|
          "E -- #{datetime} ERROR #{m}\n"
        end
        logger.error "Invalid message: #{self.to_hash}"
        return false
      end
    end

    def reply(subject:, action:, payload:)
      m = {subject: subject, action: action, payload: payload}
      Message.broadcast m, uuid
    end

    def to_hash
      hash = {}
      instance_variables.each do |var|
        hash[var.to_s.delete("@")] = instance_variable_get(var)
      end
      hash
    end
  end


  class Message
    def self.broadcast message, uuid=nil
      validate(message)
      if Cthulhu::Application.dry_run
        puts "Dry run mode enabled. Messages will not be sent."
        return
      end
      exchange = Cthulhu.channel.fanout("broadcast", durable: true)

      payload = message[:payload].to_json
      options = {
        message_id: uuid || SecureRandom.uuid,
        timestamp: Time.now.to_i,
        headers: {
          from: Cthulhu::Application.name,
          subject: message[:subject],
          action: message[:action],
          options: message[:options]
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
