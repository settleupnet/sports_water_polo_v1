# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class Misconduct
      extend BaseValidation

      class << self
        def validate!(payload)
          validate_payload(payload)
        end

        # Apply the misconduct to the game state accumulator
        def apply!(acc, event)
          acc["misconducts"] ||= { "us" => { "yellow" => 0, "red" => 0 }, "them" => { "yellow" => 0, "red" => 0 } }
          acc["misconduct_events"] ||= []

          side = event.side
          card_type = event.payload["card_type"]

          if %w[us them].include?(side) && %w[yellow red].include?(card_type)
            acc["misconducts"][side][card_type] += 1
          end

          acc["misconduct_events"] << {
            id: event.id,
            side: side,
            recipient_id: event.payload["primary_player_id"],
            card_type: card_type,
            reason: event.payload["reason"],
            is_brutality: event.payload["is_brutality"],
            time: event.payload["time"],
            period: event.payload["period"],
            seq: event.seq
          }

          acc
        end

        # Generate timeline display string
        def timeline(event)
          recipient = event.payload["primary_player_id"]
          card_type = event.payload["card_type"]
          reason = event.payload["reason"]
          time_ms = event.payload["time"]
          period = event.payload["period"]

          text = if recipient
            "#{card_type&.capitalize} card to #{recipient}"
          else
            "#{card_type&.capitalize} card"
          end
          text += " (#{reason.humanize})" if reason

          if time_ms && period
            formatted_time = format_time(time_ms)
            text += " - #{formatted_time} Q#{period}"
          end

          timestamp = if time_ms && period
            "#{format_time(time_ms)} Q#{period}"
          end

          {
            text: text,
            icon: "🟥",
            color: "red",
            timestamp: timestamp
          }
        end
      end
    end
  end
end
