module Cthulhu
  class Subscriber
    def start
      Application.start(block: false)
    end
  end
end
