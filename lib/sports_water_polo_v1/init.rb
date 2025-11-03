# frozen_string_literal: true

require "yaml"

# Ensure Sports::Registry exists
unless defined?(Sports::Registry)
  module Sports
    module Registry
      mattr_accessor :sports, default: {}

      def self.register(defn)
        key = defn[:key]
        major = defn[:major]
        sports[key] ||= {}
        sports[key][major] = defn
      end

      def self.fetch(key, major)
        sports.dig(key, major) or raise "Sport #{key}@v#{major} not registered"
      end

      def self.all
        sports
      end
    end
  end
end

# Load catalog
catalog_path = File.expand_path("../../../catalog/event_types.yaml", __FILE__)
catalog = YAML.safe_load_file(catalog_path, permitted_classes: [Symbol])

# Load club templates
require_relative 'club_templates'

# Register Water Polo v1
Sports::Registry.register(
  key: "water_polo",
  major: 1,
  catalog: catalog,
  strategies: SportsWaterPoloV1::Strategies,
  presenters: SportsWaterPoloV1::Presenters,
  roster: {
    required_fields: %i[cap_number],
    number_label: "Cap #"
  },
  club_templates: SportsWaterPoloV1::ClubTemplates.templates,
  capabilities: []
)
