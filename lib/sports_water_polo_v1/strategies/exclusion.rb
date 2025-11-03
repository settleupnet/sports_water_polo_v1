# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class Exclusion
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload, "primary_player_id")
        end

        # Apply the exclusion to the game state accumulator
        def apply!(acc, event)
          acc["exclusions"] ||= []
          acc["player_status"] ||= {}

          player_id = event.payload["primary_player_id"]
          duration = event.payload["duration"].to_i
          time_ms = event.payload["time"]
          period = event.payload["period"]

          # Track exclusion
          acc["exclusions"] << {
            id: event.id,
            side: event.side,
            player_id: player_id,
            drew_exclusion_id: event.payload["secondary_player_id"],
            duration: duration,
            reason: event.payload["reason"],
            time: time_ms,
            period: period,
            seq: event.seq
          }

          # Update player status
          if time_ms
            acc["player_status"][player_id] = {
              status: "excluded",
              until_time: calculate_return_time(time_ms, duration),
              duration: duration
            }
          end

          acc
        end

        # Generate timeline display string
        def timeline(event)
          player = event.payload["primary_player_id"]
          drew_exclusion = event.payload["secondary_player_id"]
          duration = event.payload["duration"]
          reason = event.payload["reason"]
          time_ms = event.payload["time"]
          period = event.payload["period"]

          text = "#{player} excluded"
          text += " for #{duration}s" if duration
          text += " (#{reason.humanize})" if reason
          text += " - drawn by #{drew_exclusion}" if drew_exclusion

          if time_ms && period
            formatted_time = format_time(time_ms)
            text += " - #{formatted_time} Q#{period}"
          end

          timestamp = if time_ms && period
            "#{format_time(time_ms)} Q#{period}"
          end

          {
            text: text,
            icon: "🚫",
            color: "red",
            timestamp: timestamp
          }
        end

        private

        def calculate_return_time(current_time_ms, duration_seconds)
          # Calculate return time in milliseconds
          return_time_ms = current_time_ms - (duration_seconds * 1000)

          # Return 0 if negative
          return_time_ms < 0 ? 0 : return_time_ms
        end
      end
    end
  end
end
