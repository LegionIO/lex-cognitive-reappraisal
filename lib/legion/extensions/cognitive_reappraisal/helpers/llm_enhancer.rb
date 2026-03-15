# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveReappraisal
      module Helpers
        module LlmEnhancer
          SYSTEM_PROMPT = <<~PROMPT
            You are the emotion regulation processor for an autonomous AI agent built on LegionIO.
            You practice cognitive reappraisal — re-interpreting emotional events to change their impact.
            Generate genuine, psychologically-grounded re-framings. Be specific to the event content.
            Do not dismiss or minimize. Reframe with depth and insight.
          PROMPT

          module_function

          def available?
            !!(defined?(Legion::LLM) && Legion::LLM.respond_to?(:started?) && Legion::LLM.started?)
          rescue StandardError
            false
          end

          def generate_reappraisal(event_content:, initial_appraisal:, strategy:, valence:, intensity:)
            prompt = build_generate_reappraisal_prompt(
              event_content:     event_content,
              initial_appraisal: initial_appraisal,
              strategy:          strategy,
              valence:           valence,
              intensity:         intensity
            )
            response = llm_ask(prompt)
            parse_generate_reappraisal_response(response)
          rescue StandardError => e
            Legion::Logging.warn "[cognitive_reappraisal:llm] generate_reappraisal failed: #{e.message}"
            nil
          end

          def llm_ask(prompt)
            chat = Legion::LLM.chat
            chat.with_instructions(SYSTEM_PROMPT)
            chat.ask(prompt)
          end
          private_class_method :llm_ask

          def build_generate_reappraisal_prompt(event_content:, initial_appraisal:, strategy:, valence:, intensity:)
            <<~PROMPT
              An emotional event needs cognitive reappraisal.

              EVENT: #{event_content}
              CURRENT APPRAISAL: #{initial_appraisal}
              VALENCE: #{valence} (negative = aversive, positive = pleasant)
              INTENSITY: #{intensity} (0-1, how activating)
              STRATEGY: #{strategy}

              Strategy guidelines:
              - reinterpretation: re-frame the meaning of the event
              - distancing: create psychological distance from the event
              - benefit_finding: identify positive outcomes or growth opportunities
              - normalizing: recognize this as a common experience
              - perspective_taking: view from another agent's or future self's perspective
              - temporal_distancing: project forward — how will this matter in a week/month?

              Generate a specific, insightful reappraisal using the given strategy.

              Format EXACTLY as:
              REAPPRAISAL: <1-2 sentence reappraisal that applies the strategy to this specific event>
            PROMPT
          end
          private_class_method :build_generate_reappraisal_prompt

          def parse_generate_reappraisal_response(response)
            return nil unless response&.content

            match = response.content.match(/REAPPRAISAL:\s*(.+)/im)
            return nil unless match

            { new_appraisal: match.captures.first.strip }
          end
          private_class_method :parse_generate_reappraisal_response
        end
      end
    end
  end
end
