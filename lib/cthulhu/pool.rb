module Cthulhu
  class Pool
    @@thread = nil
    def self.thread
      @@thread
    end
    def self.start
      @@thread = Thread.new do
        loop do
          message = CTHULHU_QUEUE.pop
          message.send_now
        end
      end
    end
  end
end
