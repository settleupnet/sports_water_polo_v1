# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class Comment
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload)

          true
        end

        # Apply the comment to the game state accumulator
        def apply!(acc, event)
          acc["comments"] ||= []

          acc["comments"] << {
            id: event.id,
            note: event.payload["note"],
            time: event.payload["time"],
            period: event.payload["period"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          note = event.payload["note"] || "Comment"
          time_ms = event.payload["time"]
          period = event.payload["period"]

          timestamp = if time_ms && period
            "#{format_time(time_ms)} Q#{period}"
          elsif time_ms
            format_time(time_ms)
          end

          {
            text: note,
            icon: "💬",
            color: "gray",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
