module Cthulhu
  module Notifier
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      ACTION_MAP = { destroy: "after_destroy", create: 'after_save', update: 'after_save' }

      def cthulhu_notify(options={})
        on = options.delete(:on)
        on = ACTION_MAP.keys if on.nil?

        include Cthulhu::Notifier::InstanceMethods
        on.each do |o|
          action = ACTION_MAP[o.to_sym]
          next if action.nil?

          past_tense_action = o.to_s.last == 'e' ? "#{o}d" : "#{o}ed"
          self.send( action ) { |model| model.cthulhu_publish(past_tense_action, options) }
        end
      end
    end

    module InstanceMethods
      def cthulhu_publish(action, options)
        rk = "#{self.class.name}.#{action}"
        Cthulhu::Message.new(payload: self.attributes, routing_key: rk, options: options).send
      end
    end
  end
end
