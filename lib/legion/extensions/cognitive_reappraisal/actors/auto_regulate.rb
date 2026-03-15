# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module CognitiveReappraisal
      module Actor
        class AutoRegulate < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::CognitiveReappraisal::Runners::CognitiveReappraisal
          end

          def runner_function
            'regulate_pending_events'
          end

          def time
            300
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
