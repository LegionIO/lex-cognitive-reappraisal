# frozen_string_literal: true

require 'legion/extensions/cognitive_reappraisal/version'
require 'legion/extensions/cognitive_reappraisal/helpers/constants'
require 'legion/extensions/cognitive_reappraisal/helpers/emotional_event'
require 'legion/extensions/cognitive_reappraisal/helpers/reappraisal_engine'
require 'legion/extensions/cognitive_reappraisal/runners/cognitive_reappraisal'

module Legion
  module Extensions
    module CognitiveReappraisal
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
