# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class StartShootout
      extend BaseValidation

      class << self
        def validate!(payload)
          # No validation needed for shootout start
          true
        end

        # Apply the start shootout to the game state accumulator
        def apply!(acc, event)
          acc["shootout"] ||= { "started" => true }
          acc["current_period"] = -1

          acc
        end

        # Generate timeline display string
        def timeline(event)
          {
            text: "Shootout begins",
            icon: "🎯",
            color: "yellow",
            timestamp: "Shootout"
          }
        end
      end
    end
  end
end
