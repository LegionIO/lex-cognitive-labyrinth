# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLabyrinth
      class Client
        include Runners::CognitiveLabyrinth

        def initialize(**)
          @labyrinth_engine = Helpers::LabyrinthEngine.new
        end

        private

        attr_reader :labyrinth_engine
      end
    end
  end
end
