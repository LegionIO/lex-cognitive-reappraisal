# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveReappraisal
      module Helpers
        class EmotionalEvent
          include Constants

          attr_reader :id, :content, :initial_valence, :current_valence,
                      :initial_intensity, :current_intensity, :appraisal,
                      :reappraisal_count, :created_at

          def initialize(content:, valence:, intensity:, appraisal:)
            @id                = SecureRandom.uuid
            @content           = content
            @initial_valence   = Constants.clamp(valence)
            @current_valence   = @initial_valence
            @initial_intensity = Constants.clamp_intensity(intensity)
            @current_intensity = @initial_intensity
            @appraisal         = appraisal
            @reappraisal_count = 0
            @created_at        = Time.now.utc
          end

          def reappraise!(strategy:, new_appraisal:)
            return 0.0 unless Constants.valid_strategy?(strategy)

            base_effectiveness = Constants::STRATEGY_EFFECTIVENESS[strategy]
            difficulty = @current_intensity > Constants::HIGH_INTENSITY_THRESHOLD ? Constants::REAPPRAISAL_DIFFICULTY_MULTIPLIER : 1.0
            effectiveness = (base_effectiveness * difficulty).round(10)

            valence_shift = effectiveness
            intensity_reduction = (effectiveness * 0.5).round(10)

            old_valence   = @current_valence
            old_intensity = @current_intensity

            @current_valence   = Constants.clamp(@current_valence + valence_shift)
            @current_intensity = Constants.clamp_intensity(@current_intensity - intensity_reduction)
            @appraisal         = new_appraisal
            @reappraisal_count += 1

            ((@current_valence - old_valence).abs + (old_intensity - @current_intensity).abs).round(10)
          end

          def negative?
            @current_valence < Constants::NEGATIVE_VALENCE_THRESHOLD
          end

          def intense?
            @current_intensity > Constants::HIGH_INTENSITY_THRESHOLD
          end

          def regulation_amount
            valence_change   = (@current_valence - @initial_valence).abs
            intensity_change = (@initial_intensity - @current_intensity).abs
            raw = valence_change + intensity_change
            Constants.clamp_intensity(raw / 2.0)
          end

          def valence_label
            Constants.label_for(@current_valence, Constants::VALENCE_LABELS)
          end

          def intensity_label
            Constants.label_for(@current_intensity, Constants::INTENSITY_LABELS)
          end

          def to_h
            {
              id:                @id,
              content:           @content,
              initial_valence:   @initial_valence.round(10),
              current_valence:   @current_valence.round(10),
              initial_intensity: @initial_intensity.round(10),
              current_intensity: @current_intensity.round(10),
              appraisal:         @appraisal,
              reappraisal_count: @reappraisal_count,
              negative:          negative?,
              intense:           intense?,
              regulation_amount: regulation_amount.round(10),
              valence_label:     valence_label,
              intensity_label:   intensity_label,
              created_at:        @created_at
            }
          end
        end
      end
    end
  end
end
