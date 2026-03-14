# frozen_string_literal: true

require 'securerandom'

require_relative 'cognitive_labyrinth/version'
require_relative 'cognitive_labyrinth/helpers/constants'
require_relative 'cognitive_labyrinth/helpers/node'
require_relative 'cognitive_labyrinth/helpers/labyrinth'
require_relative 'cognitive_labyrinth/helpers/labyrinth_engine'
require_relative 'cognitive_labyrinth/runners/cognitive_labyrinth'
require_relative 'cognitive_labyrinth/client'

module Legion
  module Extensions
    module CognitiveLabyrinth
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
