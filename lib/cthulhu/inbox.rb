module Cthulhu
  class Inbox
    class << self
      def create(parent: )
        inbox_exchange = Cthulhu.channel.fanout(Cthulhu.inbox_exchange_name, auto_delete: false, durable: true)
        bindings = get_bindings
        Cthulhu.routes.keys.each do |rk|
          bindings.delete_if{|b| b['routing_key'] == rk && b['source'] == parent.name}
          inbox_exchange.bind(parent, routing_key: rk)
        end
        # unbinding routes removed from the routes file

        bindings.each do |b|
          next unless b['source'] == parent.name
          inbox_exchange.unbind(b['source'], routing_key: b['routing_key'])
        end
        inbox_exchange
      end

      def get_bindings
        options = {basic_auth: {username: 'cthulhu', password: 'cthulhu'}}
        url = "#{Cthulhu.rabbit_api_url}/exchanges/#{URI.escape(Cthulhu.rabbit_vhost, '/')}/#{Cthulhu.inbox_exchange_name}/bindings/destination"
        response = ::HTTParty.get(url, options)
        JSON.parse(response.body)
      end

    end
  end
end
