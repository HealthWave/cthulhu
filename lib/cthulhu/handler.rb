module Cthulhu
  class Handler
    @@logger = Cthulhu::Application.logger
    attr_accessor :message, :properties, :headers
    def initialize(properties, message)
      @message = message
      @properties = properties
      @headers = properties.headers
    end
    def logger
      @@logger
    end
    def self.logger=(logger)
      @@logger = logger
    end
    def ack!
      "ack!"
    end
    def requeue!
      "requeue!"
    end

    def ignore!
      "ignore!"
    end
  end
end
