module Ido
  class EventProcessor
    class << self
      def process_and_fire!(event)
        if _event = process(event)
          return fire(_event)
        else
          puts " COULD NOT PROCESS EVENT"
          return false
        end
      end

      def process(event)
        puts "NORMALIZING KEYS"
        event  = Cloudfuji::Utils.normalize_keys(event)
        if validate_event(event)
          return event
        else
          puts "NOT A VALID EVENT"
          return false
        end
      end

      def validate_event(event)
        !event[:category].nil? && !event[:name].nil? && !event[:data].nil? &&
          !protected_event?(event)
      end

      def fire(event)
        puts "FIRING EVENT"
        Cloudfuji::Event.publish(event)
      end

      # Placeholder
      def protected_event?(event)
        false
      end

      # Placeholder
      def standard_event?(event)
        false
      end
    end
  end
end
