# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class WonSprint
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload, "primary_player_id")
        end

        # Apply the won sprint to the game state accumulator
        def apply!(acc, event)
          acc["sprints_won"] ||= { "us" => 0, "them" => 0 }
          acc["sprint_events"] ||= []

          side = event.side
          acc["sprints_won"][side] += 1 if %w[us them].include?(side)

          acc["sprint_events"] << {
            id: event.id,
            side: side,
            winner_id: event.payload["primary_player_id"],
            time: event.payload["time"],
            period: event.payload["period"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          winner = event.payload["primary_player_id"]
          time_ms = event.payload["time"]
          period = event.payload["period"]

          text = "#{winner} wins sprint"

          if time_ms && period
            formatted_time = format_time(time_ms)
            text += " - #{formatted_time} Q#{period}"
          end

          timestamp = if time_ms && period
            "#{format_time(time_ms)} Q#{period}"
          end

          {
            text: text,
            icon: "🏊",
            color: "green",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
