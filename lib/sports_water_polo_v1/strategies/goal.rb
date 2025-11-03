# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class Goal
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload, "primary_player_id")
        end

        # Apply the goal to the game state accumulator
        def apply!(acc, event)
          acc["goals"] ||= []
          acc["score"] ||= { "us" => 0, "them" => 0 }

          side = event.side
          acc["score"][side] += 1 if %w[us them].include?(side)

          acc["goals"] << {
            id: event.id,
            side: side,
            scorer_id: event.payload["primary_player_id"],
            assist_id: event.payload["secondary_player_id"],
            time: event.payload["time"],
            period: event.payload["period"],
            method: event.payload["method"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          scorer = event.payload["primary_player_id"]
          time_ms = event.payload["time"]
          period = event.payload["period"]
          method = event.payload["method"]

          text = "Goal by #{scorer}"
          text += " (#{method.humanize})" if method

          if time_ms && period
            formatted_time = format_time(time_ms)
            text += " - #{formatted_time} Q#{period}"
          end

          if event.payload["secondary_player_id"]
            text += " (Assist: #{event.payload['secondary_player_id']})"
          end

          timestamp = if time_ms && period
            "#{format_time(time_ms)} Q#{period}"
          end

          {
            text: text,
            icon: "🥅",
            color: "green",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
