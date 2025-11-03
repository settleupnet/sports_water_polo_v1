# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class PeriodStart
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload, "period")
        end

        # Apply the period start to the game state accumulator
        def apply!(acc, event)
          acc["period_starts"] ||= []
          acc["current_period"] = event.payload["period"]

          acc["period_starts"] << {
            id: event.id,
            period: event.payload["period"],
            time: event.payload["time"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          period = event.payload["period"]
          time_ms = event.payload["time"]

          timestamp = time_ms ? format_time(time_ms) : nil

          {
            text: "Start of Period #{period}",
            icon: "🔔",
            color: "gray",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
