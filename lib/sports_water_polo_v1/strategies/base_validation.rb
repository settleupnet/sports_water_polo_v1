# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    module BaseValidation
      def validate_payload(payload, *required_fields)
        errors = []

        # Check required fields
        required_fields.each do |field|
          errors << "#{field} is required" unless payload[field].present?
        end

        # Validate time is an integer if present (time is always optional)
        if payload["time"].present? && !payload["time"].is_a?(Integer)
          errors << "time must be an integer (milliseconds)"
        end

        raise ValidationError, errors.join("; ") if errors.any?
        true
      end

      # Helper method to format milliseconds as MM:SS.SSS for display
      # @param ms [Integer] Time in milliseconds
      # @return [String] Formatted time string (e.g., "1:23", "1:23.5", "1:23.125")
      def format_time(ms)
        return nil if ms.nil?

        total_seconds = ms / 1000
        milliseconds = ms % 1000

        minutes = total_seconds / 60
        seconds = total_seconds % 60

        result = "#{minutes}:#{seconds.to_s.rjust(2, '0')}"

        if milliseconds > 0
          # Format fractional seconds and remove trailing zeros
          fraction = (milliseconds / 1000.0).to_s[1..].sub(/0+$/, '')
          result += fraction unless fraction.empty?
        end

        result
      end
    end
  end
end
