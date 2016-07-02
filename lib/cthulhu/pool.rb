module Cthulhu
  class Pool
    @@thread = nil
    def self.thread
      @@thread
    end
    def self.start
      @@thread = Thread.new do
        if Object.const_defined?("Rails")
          Cthulhu::Application.name = Rails.application.class.parent_name
        end
        loop do
          message = CTHULHU_QUEUE.pop
          Cthulhu::Message.broadcast message
        end
      end
    end
  end
end
