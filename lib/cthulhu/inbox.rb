module Cthulhu
  class Inbox
    def self.create(parent: )
      inbox_exchange = Cthulhu.channel.fanout(Cthulhu.inbox_exchange_name, auto_delete: false, durable: true)
      bindings = get_bindings
      Cthulhu.routes.keys.each do |rk|
        bindings.delete_if{|b| b['routing_key'] == rk && b['source'] == parent}
        inbox_exchange.bind(parent, routing_key: rk)
      end
      # unbinding routes removed from the routes file
      bindings.each do |b|
        next unless b['source'] == parent
        inbox_exchange.unbind(b['source'], routing_key: b['routing_key'])
      end

    end

    def get_bindings
      options = {basic_auth: {username: 'cthulhu', password: 'cthulhu'}}
      url = "http://192.168.99.100:15672/api/exchanges/%2F/#{Cthulhu.inbox_exchange}/bindings/destination"
      response = HTTParty.get(url, options)
      JSON.parse(response.body)
    end

  end
end
