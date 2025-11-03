# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class GameEnd
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload)
        end

        # Apply the game_end to the game state accumulator
        def apply!(acc, event)
          acc["game_status"] = "completed"
          acc["final_period"] = event.payload["period"]
          acc["game_end_note"] = event.payload["note"]

          acc
        end

        # Generate timeline display string
        def timeline(event)
          note = event.payload["note"]
          text = note ? "Game Over - #{note}" : "Game Over"

          {
            text: text,
            icon: "🏁",
            color: "black",
            timestamp: nil
          }
        end
      end
    end
  end
end
