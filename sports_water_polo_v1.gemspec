# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "sports_water_polo_v1"
  spec.version = "1.0.0"
  spec.authors = ["QuickCap"]
  spec.email = ["dev@quickcap.com"]

  spec.summary = "Water Polo sport engine v1 for QuickCap"
  spec.description = "Provides validation, derivation, and presentation logic for Water Polo events"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir["{lib}/**/*", "VERSION", "catalog/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 8.0"

  spec.add_development_dependency "rspec", "~> 3.13"
end
