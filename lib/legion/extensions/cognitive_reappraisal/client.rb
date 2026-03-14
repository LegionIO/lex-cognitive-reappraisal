# frozen_string_literal: true

require 'legion/extensions/cognitive_reappraisal/helpers/constants'
require 'legion/extensions/cognitive_reappraisal/helpers/emotional_event'
require 'legion/extensions/cognitive_reappraisal/helpers/reappraisal_engine'
require 'legion/extensions/cognitive_reappraisal/runners/cognitive_reappraisal'

module Legion
  module Extensions
    module CognitiveReappraisal
      class Client
        include Runners::CognitiveReappraisal

        def initialize(engine: nil, **)
          @reappraisal_engine = engine || Helpers::ReappraisalEngine.new
        end

        private

        attr_reader :reappraisal_engine
      end
    end
  end
end
