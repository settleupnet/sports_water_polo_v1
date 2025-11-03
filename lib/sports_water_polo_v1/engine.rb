# frozen_string_literal: true

module SportsWaterPoloV1
  class Engine < ::Rails::Engine
    isolate_namespace SportsWaterPoloV1

    config.autoload_paths << root.join("lib")

    config.after_initialize do
      require_relative "init"
    end
  end
end
