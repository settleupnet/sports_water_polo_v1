# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class FiveMeter
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload, "primary_player_id")
        end

        # Apply the five meter penalty to the game state accumulator
        def apply!(acc, event)
          acc["five_meter_penalties"] ||= { "us" => 0, "them" => 0 }
          acc["five_meter_events"] ||= []

          side = event.side
          acc["five_meter_penalties"][side] += 1 if %w[us them].include?(side)

          acc["five_meter_events"] << {
            id: event.id,
            side: side,
            fouler_id: event.payload["primary_player_id"],
            drew_penalty_id: event.payload["secondary_player_id"],
            time: event.payload["time"],
            period: event.payload["period"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          fouler = event.payload["primary_player_id"]
          drew_penalty = event.payload["secondary_player_id"]
          time_ms = event.payload["time"]
          period = event.payload["period"]

          text = "5-meter penalty against #{fouler}"
          text += " (drawn by #{drew_penalty})" if drew_penalty

          if time_ms && period
            formatted_time = format_time(time_ms)
            text += " - #{formatted_time} Q#{period}"
          end

          timestamp = if time_ms && period
            "#{format_time(time_ms)} Q#{period}"
          end

          {
            text: text,
            icon: "🚩",
            color: "orange",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
