# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class Steal
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload, "primary_player_id")
        end

        # Apply the steal to the game state accumulator
        def apply!(acc, event)
          acc["steals"] ||= { "us" => 0, "them" => 0 }
          acc["steal_events"] ||= []

          side = event.side
          acc["steals"][side] += 1 if %w[us them].include?(side)

          acc["steal_events"] << {
            id: event.id,
            side: side,
            stealer_id: event.payload["primary_player_id"],
            stolen_from_id: event.payload["secondary_player_id"],
            time: event.payload["time"],
            period: event.payload["period"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          stealer = event.payload["primary_player_id"]
          stolen_from = event.payload["secondary_player_id"]
          time_ms = event.payload["time"]
          period = event.payload["period"]

          text = "Steal by #{stealer}"
          text += " from #{stolen_from}" if stolen_from

          if time_ms && period
            formatted_time = format_time(time_ms)
            text += " - #{formatted_time} Q#{period}"
          end

          timestamp = if time_ms && period
            "#{format_time(time_ms)} Q#{period}"
          end

          {
            text: text,
            icon: "🤺",
            color: "blue",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
