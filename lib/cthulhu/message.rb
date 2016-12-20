require 'securerandom'
require 'json'
module Cthulhu
  class IncomingMessage
    attr_accessor :payload,
                  :headers, # Message headers
                  :options,
                  :app_id, # App Name of the sender. Example: my-app
                  :delivery_info,
                  :properties, # Message properties
                  :message_id, # Per message unique ID
                  :reply_to, # When/if replying, send to this exchange. Defaults to the organization inbox.
                  :correlation_id, # Used to correlate RPC responses with requests. What message this message is a reply to (or corresponds to), as set by the publisher. This should be set to the UUID of the incoming message if it is an RPC call
                  :cluster_id, # This is the organization name of the sender. Set by the publisher. Example: com.example
                  :sender_fqan, # Fully Qualified App Name of the sender. Example: com.example.my-app
                  :group_id, # Unique ID to group related messages. That makes it possible to trace them. Set by the sender as a header. Immutable
                  :timestamp, # Message timestamp, as set by the publisher
                  :logger,
                  :content_type,
                  :raw_payload,
                  :routing_key,
                  :to

    def initialize(delivery_info, properties, payload)
      @logger = Cthulhu.logger.clone
      @delivery_info = delivery_info
      @properties = properties
      @headers = @properties.headers
      @content_type = @properties.type
      @raw_payload = payload
      case @content_type
      when 'application/json'
        @payload = JSON.parse payload
      # when 'object/marshal-dump'
      #   @payload = Marshal.load(payload)
      else
        @payload = payload
      end
      @routing_key = delivery_info.routing_key
      @app_id = properties.app_id
      @message_id = properties.message_id
      @reply_to = properties.reply_to
      @timestamp = properties.timestamp
      @group_id = headers['group_id']
      @cluster_id = properties.cluster_id
      @sender_fqan = "#{@cluster_id}.#{@app_id}"
      @correlation_id = properties.correlation_id
      @to = delivery_info.exchange
      @logger.formatter = proc do |severity, datetime, progname, m|
        "#{datetime.to_f} #{severity} SENT_AT=#{@timestamp.to_i} GROUP_ID=#{@group_id} FROM=#{@sender_fqan} TO=#{@to} MESSAGE_ID=#{@message_id} CORRELATION_ID=#{@correlation_id|| "nil"} | #{m}\n"
      end
    end



    def reply(payload:)
      # TODO: https://www.rabbitmq.com/tutorials/tutorial-six-ruby.html
      # message = Message.new(payload: payload, routing_key: topic,)
      # Message.broadcast m, message_id
    end

    def to_hash
      hash = {}
      instance_variables.each do |var|
        hash[var.to_s.delete("@")] = instance_variable_get(var)
      end
      hash
    end

    def call_handler
      keys = Cthulhu.routes.keys
      matching_route = ''
      Cthulhu.routes_exp.each do |route, route_exp|
        if self.routing_key.match route_exp
          matching_route = route
          break
        end
      end
      if matching_route.blank?
        logger.info "NO ROUTE MATCHED #{self.routing_key}"
        return :ignore
      end
      klass, method = Cthulhu.routes[matching_route]
      # Example: 'order.created' => 'ExampleHandler#action'
      logger.info "ROUTING #{self.routing_key} => #{klass}##{method}"
      klass.new(self).handle_action(method)
    end
  end


  class Message

    attr_accessor :payload,
                  :headers, # Message headers
                  :options,
                  :app_id, # App Name of the sender. Example: my-app
                  :delivery_info,
                  :properties, # Message properties
                  :message_id, # Per message unique ID
                  :reply_to, # When/if replying, send to this exchange. Defaults to the organization inbox.
                  :correlation_id, # Used to correlate RPC responses with requests. What message this message is a reply to (or corresponds to), as set by the publisher. This should be set to the UUID of the incoming message if it is an RPC call
                  :cluster_id, # This is the organization name of the sender. Set by the publisher. Example: com.example
                  :sender_fqan, # Fully Qualified App Name of the sender. Example: com.example.my-app
                  :group_id, # Unique ID to group related messages. That makes it possible to trace them. Set by the sender as a header. Immutable
                  :timestamp, # Message timestamp, as set by the publisher
                  :logger,
                  :content_type,
                  :raw_payload,
                  :routing_key,
                  :to

    def initialize(
      payload:,
      headers: {},
      options: nil,
      app_id: Cthulhu.app_name,
      delivery_info: nil,
      properties: nil,
      message_id: SecureRandom.uuid,
      reply_to: Cthulhu.organization_inbox_exchange_name,
      correlation_id: nil,
      cluster_id: Cthulhu.organization_inbox_exchange_name,
      sender_fqan: Cthulhu.fqan,
      group_id: SecureRandom.uuid,
      logger: Cthulhu.logger.clone,
      content_type: nil,
      routing_key:,
      to: Cthulhu.organization_inbox_exchange_name
                  )
      @options = options
      @logger = logger
      @headers = headers
      @raw_payload = payload
      if payload.is_a? Hash
        @content_type = 'application/json'
        @payload = payload.to_json
      else
        @content_type = 'application/octet-stream'
        @payload = payload
      end
      @routing_key = routing_key
      @app_id = app_id
      @message_id = message_id
      @reply_to = reply_to
      # @timestamp = timestamp # timestamp is set when sending
      @group_id = group_id
      @cluster_id = cluster_id
      @sender_fqan = sender_fqan
      @correlation_id = correlation_id
      @to = to
      @headers = headers.merge!(sender_fqan: sender_fqan, group_id: group_id)
      @logger.formatter = proc do |severity, datetime, progname, m|
        "#{datetime.to_f} #{severity} SENT_AT=#{@timestamp.to_i} GROUP_ID=#{@group_id} FROM=#{@sender_fqan} TO=#{@to} MESSAGE_ID=#{@message_id} CORRELATION_ID=#{@correlation_id|| "nil"} | #{m}\n"
      end
    end

    def prepare
      self.properties = {
        routing_key: routing_key,
        content_type: content_type,
        reply_to: reply_to,
        app_id: app_id,
        correlation_id: correlation_id,
        message_id: message_id,
        cluster_id: cluster_id,
        headers: headers,
        timestamp: timestamp,
        persistent: true
      }
      message_is_valid?
    end

    def queue
      if Cthulhu::Pool.thread.nil? || !Cthulhu::Pool.thread.alive?
        Cthulhu::Pool.start
      end
      CTHULHU_QUEUE << self
    end
    # needs exchange creation and stuff.
    def send_now
      self.timestamp = Time.now.to_i
      prepare
      # for now we can only send it to the organization inbox exchange.
      # TODO: create Cthulhu::Peer class
      case to
      when Cthulhu.organization_inbox_exchange_name
        Cthulhu.organization_inbox_exchange.publish(@payload, properties)
      when Cthulhu.inbox_exchange_name
        Cthulhu.inbox_exchange.publish(@payload, properties)
      end
      logger.info "MESSAGE SENT: #{self.inspect}"
    end

    def message_is_valid?
      params = []
      params << "payload" if payload.nil?
      params << "headers" if headers.nil?
      params << "app_id" if app_id.blank?
      params << "properties" if properties.nil?
      params << "message_id" if message_id.blank?
      params << "reply_to" if reply_to.blank?
      # raise "correlation_id is blank" if correlation_id.blank?
      params << "cluster_id" if cluster_id.blank?
      params << "sender_fqan" if sender_fqan.blank?
      params << "group_id" if group_id.blank?
      params << "logger" if logger.nil?
      params << "content_type" if content_type.blank?
      params << "routing_key" if routing_key.blank?
      params << "to" if to.blank?
      params << "timestamp" if timestamp.nil?
      raise "Missing parameters #{params}" if params.any?
    end

    def payload
      p = @payload
      if content_type == 'application/json'
        JSON.parse p
      else
        p
      end
    end
  end
end
