# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveReappraisal
      module Helpers
        class ReappraisalEngine
          include Constants

          attr_reader :events, :reappraisal_log

          def initialize
            @events          = {}
            @reappraisal_log = []
          end

          def register_event(content:, valence:, intensity:, appraisal:)
            event = EmotionalEvent.new(
              content:   content,
              valence:   valence,
              intensity: intensity,
              appraisal: appraisal
            )

            @events.shift while @events.size >= Constants::MAX_EVENTS
            @events[event.id] = event
            event
          end

          def reappraise(event_id:, strategy:, new_appraisal:)
            event = @events[event_id]
            return { success: false, reason: :event_not_found } unless event
            return { success: false, reason: :invalid_strategy } unless Constants.valid_strategy?(strategy)

            old_valence   = event.current_valence
            old_intensity = event.current_intensity

            change = event.reappraise!(strategy: strategy, new_appraisal: new_appraisal)

            log_entry = {
              event_id:         event_id,
              strategy:         strategy,
              valence_change:   (event.current_valence - old_valence).round(10),
              intensity_change: (old_intensity - event.current_intensity).round(10),
              applied_at:       Time.now.utc
            }

            @reappraisal_log.shift while @reappraisal_log.size >= Constants::MAX_REAPPRAISALS
            @reappraisal_log << log_entry

            {
              success:           true,
              event_id:          event_id,
              strategy:          strategy,
              change:            change.round(10),
              current_valence:   event.current_valence.round(10),
              current_intensity: event.current_intensity.round(10)
            }
          end

          def auto_reappraise(event_id:)
            event = @events[event_id]
            return { success: false, reason: :event_not_found } unless event

            strategy = select_strategy(event)
            new_appraisal = "auto-reappraised via #{strategy}"
            reappraise(event_id: event_id, strategy: strategy, new_appraisal: new_appraisal)
          end

          def negative_events
            @events.values.select(&:negative?)
          end

          def intense_events
            @events.values.select(&:intense?)
          end

          def most_regulated(limit: 5)
            @events.values
                   .sort_by { |e| -e.regulation_amount }
                   .first(limit)
          end

          def strategy_effectiveness
            grouped = @reappraisal_log.group_by { |entry| entry[:strategy] }
            grouped.transform_values do |entries|
              changes = entries.map { |e| e[:valence_change] }
              changes.sum.to_f / changes.size
            end
          end

          def average_regulation
            return 0.0 if @events.empty?

            total = @events.values.sum(&:regulation_amount)
            (total / @events.size).round(10)
          end

          def overall_regulation_ability
            return 0.0 if @events.empty?

            regulated_count = @events.values.count { |e| e.regulation_amount > 0.0 }
            mean_reg        = average_regulation
            coverage        = regulated_count.to_f / @events.size

            ((mean_reg + coverage) / 2.0).round(10)
          end

          def reappraisal_report
            {
              total_events:               @events.size,
              total_reappraisals:         @reappraisal_log.size,
              negative_events:            negative_events.size,
              intense_events:             intense_events.size,
              average_regulation:         average_regulation,
              overall_regulation_ability: overall_regulation_ability,
              strategy_effectiveness:     strategy_effectiveness,
              most_regulated:             most_regulated(limit: 3).map(&:to_h)
            }
          end

          def to_h
            {
              events:                     @events.transform_values(&:to_h),
              reappraisal_log:            @reappraisal_log,
              average_regulation:         average_regulation,
              overall_regulation_ability: overall_regulation_ability,
              strategy_effectiveness:     strategy_effectiveness
            }
          end

          private

          def select_strategy(event)
            if event.negative? && event.intense?
              :distancing
            elsif event.negative?
              :reinterpretation
            elsif event.intense?
              :temporal_distancing
            else
              :benefit_finding
            end
          end
        end
      end
    end
  end
end
