module Cthulhu
  class Handler
    def self.descendants
      d = ObjectSpace.each_object(Class).select { |klass| klass < self }
      d.map do |klass|
        klass.instance_methods(false).map do |m|
          x = {name: m}
          x[:arguments] = self.method(m).parameters.map do |p|
            {p[1] => p[0] == :req ? true : false }
          end
          x
        end
      end
    end

    attr_accessor :message, :properties, :headers,
                  :payload, :logger

    def initialize(message)
      @logger = ::Cthulhu.logger.clone
      @message = message
      @payload = @message.payload
      @properties = @message.properties
      @headers = @message.headers
      @logger.formatter = proc do |severity, datetime, progname, m|
        "#{datetime.to_f} #{severity} SENT_AT=#{@message.timestamp.to_i} GROUP_ID=#{@message.group_id} FROM=#{@message.sender_fqan} TO=#{@message.to} MESSAGE_ID=#{@message.message_id} CORRELATION_ID=#{@message.correlation_id|| "nil"} | #{m}\n"
      end
      @logger.info "MESSAGE RECEIVED: #{@payload}"
    end

    class << self
      attr_accessor :callbacks
      def before_action method, opts={}
        register_callback(:before, method, opts)
      end

      def after_action method, opts={}
        register_callback(:after, method, opts)
      end

      def filter_action method, opts={}
        register_callback(:filter, method, opts)
      end

      def register_callback queue, method, opts
        callbacks[queue] = {} unless callbacks[queue]

        callbacks[queue][method] = opts
      end

      def callbacks
        @callbacks ||= {}
      end

    end

    def ack!
      @logger.info "ACKNOWLEDGED"
      return :ack
    end

    def requeue!
      @logger.info "REQUEUED"
      return :requeue
    end

    def ignore!
      @logger.info "IGNORED"
      return :ignore
    end

    def callbacks
      self.class.callbacks
    end

    def handle_action method_name
      if !filter_callbacks_pass?(method_name)
        self.ack!
        return
      end

      before_callbacks(method_name)
      response = self.public_send(method_name)
      after_response = after_callbacks(method_name)
      if [:ack, :requeue, :ignore].include? response
        return response
      else
        return after_response.first
      end
    end

    private
      def expects
      end
      def filter_callbacks_pass? method_name
        filters = fire_callbacks(:filter, method_name)
        filters.empty? || filters.all? {|filter| filter.nil? || filter }
      end

      def before_callbacks method_name
        fire_callbacks(:before, method_name)
      end

      def after_callbacks method_name
        fire_callbacks(:after, method_name)
      end

      def fire_callbacks queue, method_name
        return [] if callbacks[queue].nil?

        callbacks[queue].map do |action, opts|
          self.send(action) if opts[:only].nil? || Array(opts[:only]).map(&:to_s).include?(method_name)
        end
      end
  end
end
