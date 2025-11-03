# frozen_string_literal: true

module SportsWaterPoloV1
  module Presenters
    class Timeline
      class << self
        # Generate a formatted timeline from game events
        def format(events, options = {})
          include_score = options.fetch(:include_score, true)
          grouped = options.fetch(:grouped, false)

          timeline_items = events.map do |event|
            format_event(event, include_score)
          end

          grouped ? group_by_period(timeline_items) : timeline_items
        end

        # Format a single event for timeline display
        def format_event(event, include_score = true)
          strategy = event.strategy
          base_timeline = strategy.timeline(event)

          item = {
            id: event.id,
            seq: event.seq,
            kind: event.kind,
            side: event.side,
            text: base_timeline[:text],
            icon: base_timeline[:icon],
            color: base_timeline[:color],
            timestamp: base_timeline[:timestamp],
            created_at: event.created_at
          }

          # Add current score if this is a goal and score tracking is enabled
          if include_score && event.kind == "goal"
            item[:score_snapshot] = calculate_score_at_event(event)
          end

          item
        end

        # Generate a broadcast-style description
        def broadcast(event)
          case event.kind
          when "goal"
            broadcast_goal(event)
          when "exclusion"
            broadcast_exclusion(event)
          when "timeout"
            broadcast_timeout(event)
          when "period_end"
            "The #{ordinal(event.payload['period'])} period has ended."
          when "game_end"
            "That's the final whistle! The game is over."
          else
            event.strategy.timeline(event)[:text]
          end
        end

        private

        def broadcast_goal(event)
          scorer = event.payload["scorer_id"]
          method = event.payload["method"]
          time = event.payload["time"]
          period = event.payload["period"]

          text = "GOAL! #{scorer} scores"
          text += " with a #{method.humanize.downcase}" if method
          text += " at #{time} in the #{ordinal(period)} period"

          if event.payload["assist_id"]
            text += ", assisted by #{event.payload['assist_id']}"
          end

          text + "!"
        end

        def broadcast_exclusion(event)
          player = event.payload["player_id"]
          duration = event.payload["duration"]
          reason = event.payload["reason"]

          text = "#{player} has been excluded for #{duration} seconds"
          text += " due to #{reason.humanize.downcase}"
          text + "."
        end

        def broadcast_timeout(event)
          team = event.payload["team"]
          "#{team.capitalize} has called a timeout."
        end

        def calculate_score_at_event(event)
          game = event.game
          home_goals = game.events
                          .where(kind: "goal", side: "home")
                          .where("seq <= ?", event.seq)
                          .count
          away_goals = game.events
                          .where(kind: "goal", side: "away")
                          .where("seq <= ?", event.seq)
                          .count

          { home: home_goals, away: away_goals }
        end

        def group_by_period(timeline_items)
          timeline_items.group_by do |item|
            # Extract period from timestamp (e.g., "5:30 Q2" -> 2)
            item[:timestamp]&.match(/Q(\d+)/)&.captures&.first&.to_i || 0
          end
        end

        def ordinal(number)
          num = number.to_i
          case num
          when 1 then "1st"
          when 2 then "2nd"
          when 3 then "3rd"
          when 4 then "4th"
          else "#{num}th"
          end
        end
      end
    end
  end
end
