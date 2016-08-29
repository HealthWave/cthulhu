module Cthulhu
  module Notifier
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      ACTION_MAP = { destroy: "after_destroy", create: 'after_save', update: 'after_save' }

      def cthulhu_notify(options={})
        changed = options.delete(:on_change)

        on = options.delete(:on)
        on = ACTION_MAP.keys if on.nil? && changed.nil?

        include Cthulhu::Notifier::InstanceMethods
        on.each do |o|
          method = ACTION_MAP[o.to_sym]
          next if method.nil?

          action = o.last == 'e' ? "#{o}d" : "#{o}ed"
          self.send( method ) { |model| model.cthulhu_publish(action, options) }
        end

        changed.each do |attribute|
          before_save do |model|
            return unless model.send("#{attribute}_changed?")
            payload = {
              "#{model.class.name}_id" => model.id,
              to: model.send(attribute),
              from: model.send("#{attribute}_was",
              datetime: DateTime.now
            }

            model.cthulhu_publish( "#{attribute}_updated", options.merge({payload: payload}) )
          end
        end
      end
    end

    module InstanceMethods
      def cthulhu_publish(action, options)
        paylod = options.delete(:payload)
        Cthulhu.publish(subject: self.class.name, action: action, options: options, payload: payload || self.attributes )
      end
    end
  end
end
