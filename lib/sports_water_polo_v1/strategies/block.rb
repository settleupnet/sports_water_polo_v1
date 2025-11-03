# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class Block
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload, "primary_player_id")
        end

        # Apply the block to the game state accumulator
        def apply!(acc, event)
          acc["blocks"] ||= { "us" => 0, "them" => 0 }
          acc["block_events"] ||= []

          side = event.side
          acc["blocks"][side] += 1 if %w[us them].include?(side)

          acc["block_events"] << {
            id: event.id,
            side: side,
            blocker_id: event.payload["primary_player_id"],
            shooter_id: event.payload["secondary_player_id"],
            time: event.payload["time"],
            period: event.payload["period"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          blocker = event.payload["primary_player_id"]
          shooter = event.payload["secondary_player_id"]
          time_ms = event.payload["time"]
          period = event.payload["period"]

          text = "Block by #{blocker}"
          text += " on #{shooter}" if shooter

          if time_ms && period
            formatted_time = format_time(time_ms)
            text += " - #{formatted_time} Q#{period}"
          end

          timestamp = if time_ms && period
            "#{format_time(time_ms)} Q#{period}"
          end

          {
            text: text,
            icon: "🛡️",
            color: "purple",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
