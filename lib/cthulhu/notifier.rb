module Cthulhu
  module Notifier
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      ACTION_MAP = { destroy: "after_destory", create: 'after_save', update: 'after_save' }

      def cthulhu_notify(options)
        on = options.delete(:on)
        on = ACTION_MAP.keys if on.nil?

        include Cthulhu::Notifier::InstanceMethods
        on.each do |o|
          action = ACTION_MAP[o.to_sym]
          next if action.nil?
          self.send( action, {|model| model.cthulhu_publish("#{o}ed", options)} )
        end
      end
    end

    module InstanceMethods
      def cthulhu_publish(action, options)
        Cthulhu.publish(subject: self.class.name, action: action, options: options, payload: self.attributes )
      end
    end
  end
end
