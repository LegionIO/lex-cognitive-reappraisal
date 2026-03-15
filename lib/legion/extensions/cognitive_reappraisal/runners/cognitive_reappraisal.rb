# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveReappraisal
      module Runners
        module CognitiveReappraisal
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def register_event(content:, valence:, intensity:, appraisal:, engine: nil, **)
            eng = engine || reappraisal_engine
            event = eng.register_event(content: content, valence: valence, intensity: intensity, appraisal: appraisal)

            Legion::Logging.debug "[cognitive_reappraisal] registered event id=#{event.id[0..7]} " \
                                  "valence=#{event.initial_valence.round(2)} intensity=#{event.initial_intensity.round(2)}"

            {
              success:   true,
              event_id:  event.id,
              valence:   event.initial_valence.round(10),
              intensity: event.initial_intensity.round(10),
              negative:  event.negative?,
              intense:   event.intense?
            }
          end

          def reappraise_event(event_id:, strategy:, new_appraisal:, engine: nil, **)
            unless Helpers::Constants.valid_strategy?(strategy)
              return { success: false, reason: :invalid_strategy, valid_strategies: Helpers::Constants::STRATEGIES }
            end

            eng = engine || reappraisal_engine
            appraisal = llm_appraisal_for(eng.events[event_id], strategy) || new_appraisal
            result = eng.reappraise(event_id: event_id, strategy: strategy, new_appraisal: appraisal)

            if result[:success]
              Legion::Logging.info "[cognitive_reappraisal] reappraised event=#{event_id[0..7]} " \
                                   "strategy=#{strategy} change=#{result[:change].round(2)}"
            else
              Legion::Logging.debug "[cognitive_reappraisal] reappraisal failed event=#{event_id[0..7]} reason=#{result[:reason]}"
            end

            result
          end

          def auto_reappraise_event(event_id:, engine: nil, **)
            eng   = engine || reappraisal_engine
            event = eng.events[event_id]
            return { success: false, reason: :event_not_found } unless event

            strategy  = select_strategy_for(event)
            appraisal = llm_appraisal_for(event, strategy) || "auto-reappraised via #{strategy}"
            result    = eng.reappraise(event_id: event_id, strategy: strategy, new_appraisal: appraisal)

            if result[:success]
              Legion::Logging.info "[cognitive_reappraisal] auto-reappraised event=#{event_id[0..7]} " \
                                   "strategy=#{strategy}"
            else
              Legion::Logging.debug "[cognitive_reappraisal] auto-reappraisal failed: #{result[:reason]}"
            end

            result
          end

          def negative_events(engine: nil, **)
            eng    = engine || reappraisal_engine
            events = eng.negative_events
            Legion::Logging.debug "[cognitive_reappraisal] negative events count=#{events.size}"
            { events: events.map(&:to_h), count: events.size }
          end

          def intense_events(engine: nil, **)
            eng    = engine || reappraisal_engine
            events = eng.intense_events
            Legion::Logging.debug "[cognitive_reappraisal] intense events count=#{events.size}"
            { events: events.map(&:to_h), count: events.size }
          end

          def most_regulated_events(limit: 5, engine: nil, **)
            eng    = engine || reappraisal_engine
            events = eng.most_regulated(limit: limit)
            Legion::Logging.debug "[cognitive_reappraisal] most regulated count=#{events.size}"
            { events: events.map(&:to_h), count: events.size }
          end

          def reappraisal_status(engine: nil, **)
            eng = engine || reappraisal_engine
            Legion::Logging.debug "[cognitive_reappraisal] status: overall=#{eng.overall_regulation_ability.round(2)}"
            {
              overall_regulation_ability: eng.overall_regulation_ability,
              average_regulation:         eng.average_regulation,
              total_events:               eng.events.size,
              total_reappraisals:         eng.reappraisal_log.size,
              strategy_effectiveness:     eng.strategy_effectiveness
            }
          end

          def reappraisal_report(engine: nil, **)
            eng = engine || reappraisal_engine
            Legion::Logging.debug '[cognitive_reappraisal] generating report'
            { success: true, report: eng.reappraisal_report }
          end

          def regulate_pending_events(engine: nil, **)
            eng       = engine || reappraisal_engine
            events    = eng.events.values
            checked   = events.size
            regulated = 0
            event_ids = []

            events.each do |event|
              next unless event.negative? && event.reappraisal_count.zero?

              result = eng.auto_reappraise(event_id: event.id)
              next unless result[:success]

              regulated += 1
              event_ids << event.id
            end

            Legion::Logging.debug "[reappraisal] regulate pending: checked=#{checked} regulated=#{regulated}"
            { checked: checked, regulated: regulated, event_ids: event_ids }
          end

          private

          def reappraisal_engine
            @reappraisal_engine ||= Helpers::ReappraisalEngine.new
          end

          def llm_appraisal_for(event, strategy)
            return nil unless event && Helpers::LlmEnhancer.available?

            result = Helpers::LlmEnhancer.generate_reappraisal(
              event_content:     event.content,
              initial_appraisal: event.appraisal,
              strategy:          strategy,
              valence:           event.current_valence,
              intensity:         event.current_intensity
            )
            result&.fetch(:new_appraisal, nil)
          end

          def select_strategy_for(event)
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
