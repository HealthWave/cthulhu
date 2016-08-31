module Cthulhu
  module Notifier
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def cthulhu_notify(options={})
        include Cthulhu::Notifier::InstanceMethods
        @notifier = Notifier.new(self, options)

        @notifier.setup_lifecyle_events!
      end

      def cthulhu_changed(options={}, &block)
        include Cthulhu::Notifier::InstanceMethods
        options[:payload] = block if block_given?
        @notifier = Notifier.new(self, options)

        @notifier.setup_change_events!
      end

    end

    module InstanceMethods
      def cthulhu_publish(action, options)
        paylod = options.delete(:payload)
        Cthulhu.publish(subject: self.class.name, action: action, options: options, payload: payload || self.attributes )
      end
    end

    class Notifier
      ACTION_MAP = { destroy: "after_destroy", create: 'after_save', update: 'after_save' }

      attr_reader :changed, :on, :options, :klass, :payload

      def initialize(klass, options={})
        @klass = klass
        @changed = options.delete(:on_change)

        @on = options.delete(:on)
        @on = ACTION_MAP.keys if on.nil? && changed.nil?

        @options = options
      end

      def setup_lifecyle_events!
        on.each do |o|
          method = ACTION_MAP[o.to_sym]
          next if method.nil?
          self.send( method ) { |instance| instance.cthulhu_publish( past_tensify(aciton), options ) }
        end
      end

      def setup_change_events!
        changed.each do |attribute|
          before_save do |instance|
            return unless instance.send("#{attribute}_changed?")
            payload = generate_payload( instance, attribute, options.delete(:payload) )

            instance.cthulhu_publish( "#{attribute}_updated", options.merge({payload: payload}) )
          end
        end
      end

      private
        def past_tensify(action)
          action = o.last == 'e' ? "#{o}d" : "#{o}ed"
        end

        def generate_payload(instance, attribute, payload)
          case
          when payload.respond_to? :call
            payload.call
          when payload.is_a? Symbol, payload.is_a? String
            instance.send(payload)
          else
            default_payload(instance, attribute)
          end
        end

        def default_payload(instance, attribute)
          return {
            "#{instance.class.name}_id" => instance.id,
            "to" => instance.send(attribute),
            "from" => instance.send("#{attribute}_was"),
            "datetime" => DateTime.now
          }
        end
    end

  end
end
