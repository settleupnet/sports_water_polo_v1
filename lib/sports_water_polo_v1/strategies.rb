# frozen_string_literal: true

module SportsWaterPoloV1
  module Strategies
    class ValidationError < StandardError; end
  end
end

require_relative "strategies/base_validation"

module SportsWaterPoloV1
  module Strategies
    def self.for_kind(kind)
      case kind
      when "goal" then Goal
      when "exclusion" then Exclusion
      when "steal" then Steal
      when "five_meter" then FiveMeter
      when "won_sprint" then WonSprint
      when "block" then Block
      when "misconduct" then Misconduct
      when "timeout" then Timeout
      when "period_start" then PeriodStart
      when "period_end" then PeriodEnd
      when "start_shootout" then StartShootout
      when "comment" then Comment
      when "game_end" then GameEnd
      else
        raise ArgumentError, "Unknown event kind: #{kind}"
      end
    end
  end
end

require_relative "strategies/goal"
require_relative "strategies/exclusion"
require_relative "strategies/steal"
require_relative "strategies/five_meter"
require_relative "strategies/won_sprint"
require_relative "strategies/block"
require_relative "strategies/misconduct"
require_relative "strategies/timeout"
require_relative "strategies/period_start"
require_relative "strategies/period_end"
require_relative "strategies/start_shootout"
require_relative "strategies/comment"
require_relative "strategies/game_end"
