require 'ostruct'
require 'json'
require 'timeout'

module Cthulhu
  APPS_ARRAY = ["HwAdmin"]
  def self.const_missing(name)
    if APPS_ARRAY.include? name.to_s
      name = const_set name.to_s, Class.new(RemoteApp)
    else
      super
    end
  end
  class RemoteApp
    # def self.const_missing(name)
    #   name = const_set name.to_s, Class.new(RemoteConst)
    # end
    def self.run(code)
      app_name = name.split("::").last
      message = code
      ch = Cthulhu.channel
      inx = ch.direct("#{Cthulhu::Application.name}.direct")
      outx = ch.direct("#{app_name}.direct")
      reply_queue = ch.queue("", exclusive: true, auto_delete: true).bind(inx, routing_key: "rpc")
      options = {
        routing_key: "rpc",
        headers: {
          from: Cthulhu::Application.name,
          reply_to: inx.name
        }
      }
      outx.publish(message, options)
      response = 'empty'
      begin
        Timeout::timeout(5) do
          consumer = reply_queue.subscribe(block: false, message_max: 1) do |delivery_info, properties, payload|
            if payload == "null"
              response = nil
            else
              response = JSON.parse(payload, object_class: OpenStruct)
            end
          end
          loop do
            if response != 'empty'
              consumer.cancel
              break response
            end
          end
        end
      rescue Timeout::Error
        puts "Timed out waiting for response"
      end
    end
  end

  # C::HwAdmin.run "Spree::Order.find(344324)"


  # class RemoteConst
  #   def self.const_missing(name)
  #     name = const_set name.to_s, Class.new(RemoteConst)
  #   end
  #   def self.method_missing(method_name, *args, &block)
  #     constants = name.split("::")
  #     final_method = constants[2,constants.size].join("::")
  #     app_name = constants[1]
  #     code = "#{final_method}.#{method_name}(#{args.join(',')})"
  #     puts "You called #{code} on app #{app_name}"
  #     message = code
  #     ch = Cthulhu.channel
  #     inx = ch.direct("#{Cthulhu::Application.name}.direct")
  #     outx = ch.direct("#{app_name}.direct")
  #     reply_queue = ch.queue("", exclusive: true, auto_delete: true).bind(inx, routing_key: "rpc")
  #     options = {
  #       routing_key: "rpc",
  #       headers: {
  #         from: Cthulhu::Application.name,
  #         reply_to: inx.name
  #       }
  #     }
  #     outx.publish(message, options)
  #     response = nil
  #     consumer = reply_queue.subscribe(block: false, message_max: 1) do |delivery_info, properties, payload|
  #       puts "got response!"
  #       response = JSON.parse(payload, object_class: OpenStruct)
  #     end
  #     puts "Waiting for reply."
  #     loop do
  #       if !response.nil?
  #         consumer.cancel
  #         break response
  #       end
  #     end
  #   end
  # end

end
