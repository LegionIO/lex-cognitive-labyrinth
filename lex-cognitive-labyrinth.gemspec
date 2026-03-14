# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_labyrinth/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-labyrinth'
  spec.version       = Legion::Extensions::CognitiveLabyrinth::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Labyrinth'
  spec.description   = 'Maze-like problem spaces for agentic reasoning — paths, dead ends, backtracking, ' \
                       'breadcrumb trails, Ariadne\'s thread (guiding heuristic), and Minotaur encounters ' \
                       '(dangerous misconceptions)'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-labyrinth'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-cognitive-labyrinth'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-cognitive-labyrinth'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-cognitive-labyrinth'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-cognitive-labyrinth/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
end
