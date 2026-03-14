# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveReappraisal
      module Helpers
        module Constants
          MAX_EVENTS       = 300
          MAX_REAPPRAISALS = 500

          STRATEGIES = %i[
            reinterpretation
            distancing
            benefit_finding
            normalizing
            perspective_taking
            temporal_distancing
          ].freeze

          STRATEGY_EFFECTIVENESS = {
            reinterpretation:    0.25,
            distancing:          0.15,
            benefit_finding:     0.20,
            normalizing:         0.12,
            perspective_taking:  0.18,
            temporal_distancing: 0.10
          }.freeze

          VALENCE_LABELS = {
            (0.5..)       => :positive,
            (0.1...0.5)   => :mildly_positive,
            (-0.1...0.1)  => :neutral,
            (-0.5...-0.1) => :mildly_negative,
            (..-0.5)      => :negative
          }.freeze

          INTENSITY_LABELS = {
            (0.8..)     => :overwhelming,
            (0.6...0.8) => :intense,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :mild,
            (..0.2)     => :faint
          }.freeze

          REGULATION_LABELS = {
            (0.8..)     => :excellent,
            (0.6...0.8) => :good,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :poor,
            (..0.2)     => :minimal
          }.freeze

          NEGATIVE_VALENCE_THRESHOLD      = -0.3
          HIGH_INTENSITY_THRESHOLD        = 0.7
          REAPPRAISAL_DIFFICULTY_MULTIPLIER = 0.5

          module_function

          def label_for(value, label_map)
            label_map.find { |range, _label| range.cover?(value) }&.last || :unknown
          end

          def valid_strategy?(strategy)
            STRATEGIES.include?(strategy)
          end

          def clamp(value, min = -1.0, max = 1.0)
            value.clamp(min, max)
          end

          def clamp_intensity(value)
            value.clamp(0.0, 1.0)
          end
        end
      end
    end
  end
end
