module Cthulhu
  class Inbox
    def self.create(parent: )
      inbox_exchange = Cthulhu.channel.fanout(Cthulhu.inbox_exchange_name, auto_delete: false)
      Cthulhu.routes.keys.each do |rk|
        inbox_exchange.bind(parent, routing_key: rk)
      end
      inbox_exchange
    end
  end
end
