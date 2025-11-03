# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class Timeout
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload)
        end

        # Apply the timeout to the game state accumulator
        def apply!(acc, event)
          acc["timeouts"] ||= { "home" => [], "away" => [] }

          team = event.payload["team"]
          acc["timeouts"][team] ||= []
          acc["timeouts"][team] << {
            id: event.id,
            time: event.payload["time"],
            period: event.payload["period"],
            duration: event.payload["duration"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          team = event.payload["team"]
          time_ms = event.payload["time"]
          period = event.payload["period"]

          if time_ms && period
            formatted_time = format_time(time_ms)
            text = "#{team.capitalize} timeout - #{formatted_time} Q#{period}"
            timestamp = "#{formatted_time} Q#{period}"
          else
            text = "#{team.capitalize} timeout"
            timestamp = nil
          end

          {
            text: text,
            icon: "⏱️",
            color: "blue",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
