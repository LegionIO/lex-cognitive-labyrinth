# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLabyrinth
      module Helpers
        module Constants
          NODE_TYPES = %i[corridor junction dead_end entrance exit minotaur_lair].freeze

          MAX_LABYRINTHS = 20
          MAX_NODES      = 200

          COMPLEXITY_LABELS = {
            (0.0...0.2) => :trivial,
            (0.2...0.4) => :simple,
            (0.4...0.6) => :moderate,
            (0.6...0.8) => :complex,
            (0.8..1.0)  => :labyrinthine
          }.freeze

          DANGER_LABELS = {
            (0.0...0.25) => :safe,
            (0.25...0.5) => :uncertain,
            (0.5...0.75) => :hazardous,
            (0.75..1.0)  => :lethal
          }.freeze

          DEFAULT_DANGER_LEVEL    = 0.0
          MINOTAUR_DANGER_LEVEL   = 0.9
          DEAD_END_COMPLEXITY_HIT = 0.1
        end
      end
    end
  end
end
