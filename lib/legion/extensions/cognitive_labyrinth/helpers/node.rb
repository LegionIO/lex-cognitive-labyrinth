# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLabyrinth
      module Helpers
        class Node
          attr_reader   :node_id, :node_type, :content, :connections, :danger_level
          attr_accessor :visited

          def initialize(node_id:, node_type:, content: nil, danger_level: Constants::DEFAULT_DANGER_LEVEL)
            unless Constants::NODE_TYPES.include?(node_type)
              raise ArgumentError, "unknown node_type: #{node_type.inspect}; must be one of #{Constants::NODE_TYPES.inspect}"
            end

            @node_id      = node_id
            @node_type    = node_type
            @content      = content
            @connections  = []
            @visited      = false
            @danger_level = danger_level.clamp(0.0, 1.0)
          end

          def connect!(other_id)
            @connections << other_id unless @connections.include?(other_id)
            self
          end

          def disconnect!(other_id)
            @connections.delete(other_id)
            self
          end

          def dead_end?
            @node_type == :dead_end || (@connections.empty? && @node_type != :entrance && @node_type != :exit)
          end

          def junction?
            @node_type == :junction || @connections.size >= 3
          end

          def dangerous?
            @node_type == :minotaur_lair || @danger_level >= 0.5
          end

          def to_h
            {
              node_id:      @node_id,
              node_type:    @node_type,
              content:      @content,
              connections:  @connections.dup,
              visited:      @visited,
              danger_level: @danger_level
            }
          end
        end
      end
    end
  end
end
