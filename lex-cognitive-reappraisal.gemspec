# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_reappraisal/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-reappraisal'
  spec.version       = Legion::Extensions::CognitiveReappraisal::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Reappraisal'
  spec.description   = 'Emotion regulation via cognitive reappraisal strategies for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-reappraisal'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-cognitive-reappraisal'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-cognitive-reappraisal'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-cognitive-reappraisal'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-cognitive-reappraisal/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-cognitive-reappraisal.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
end
