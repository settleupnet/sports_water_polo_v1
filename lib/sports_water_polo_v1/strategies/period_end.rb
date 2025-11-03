# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class PeriodEnd
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload, "period")
        end

        # Apply the period_end to the game state accumulator
        def apply!(acc, event)
          acc["periods_completed"] ||= []

          period = event.payload["period"]
          acc["periods_completed"] << period unless acc["periods_completed"].include?(period)

          acc
        end

        # Generate timeline display string
        def timeline(event)
          period = event.payload["period"]

          {
            text: "End of Period #{period}",
            icon: "🔔",
            color: "gray",
            timestamp: "#{format_time(0)} Q#{period}"
          }
        end
      end
    end
  end
end
