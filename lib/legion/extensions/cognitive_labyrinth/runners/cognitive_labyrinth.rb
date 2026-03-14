# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLabyrinth
      module Runners
        module CognitiveLabyrinth
          extend self

          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def create_labyrinth(name:, domain: nil, labyrinth_id: nil, engine: nil, **)
            raise ArgumentError, 'name is required' if name.nil? || name.to_s.strip.empty?

            result = resolve_engine(engine).create_labyrinth(name: name, domain: domain, labyrinth_id: labyrinth_id)
            Legion::Logging.debug "[cognitive_labyrinth] runner: created labyrinth #{result.labyrinth_id[0..7]}"
            { success: true, labyrinth_id: result.labyrinth_id, name: result.name, domain: result.domain }
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] create_labyrinth error: #{e.message}"
            { success: false, error: e.message }
          end

          def add_node(labyrinth_id:, node_type:, content: nil, danger_level: nil, node_id: nil, engine: nil, **)
            raise ArgumentError, 'labyrinth_id is required' if labyrinth_id.nil?
            raise ArgumentError, 'node_type is required' if node_type.nil?

            node = resolve_engine(engine).add_node_to(
              labyrinth_id: labyrinth_id, node_type: node_type,
              content: content, danger_level: danger_level, node_id: node_id
            )
            { success: true, node_id: node.node_id, node_type: node.node_type }
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] add_node error: #{e.message}"
            { success: false, error: e.message }
          end

          def connect_nodes(labyrinth_id:, from_id:, to_id:, bidirectional: true, engine: nil, **)
            raise ArgumentError, 'labyrinth_id is required' if labyrinth_id.nil?

            resolve_engine(engine).connect_nodes(
              labyrinth_id: labyrinth_id, from_id: from_id, to_id: to_id, bidirectional: bidirectional
            )
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] connect_nodes error: #{e.message}"
            { success: false, error: e.message }
          end

          def move(labyrinth_id:, node_id:, engine: nil, **)
            raise ArgumentError, 'labyrinth_id is required' if labyrinth_id.nil?
            raise ArgumentError, 'node_id is required' if node_id.nil?

            resolve_engine(engine).move(labyrinth_id: labyrinth_id, node_id: node_id)
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] move error: #{e.message}"
            { success: false, error: e.message }
          end

          def backtrack(labyrinth_id:, engine: nil, **)
            raise ArgumentError, 'labyrinth_id is required' if labyrinth_id.nil?

            resolve_engine(engine).backtrack(labyrinth_id: labyrinth_id)
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] backtrack error: #{e.message}"
            { success: false, error: e.message }
          end

          def follow_thread(labyrinth_id:, engine: nil, **)
            raise ArgumentError, 'labyrinth_id is required' if labyrinth_id.nil?

            resolve_engine(engine).follow_thread(labyrinth_id: labyrinth_id)
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] follow_thread error: #{e.message}"
            { success: false, error: e.message }
          end

          def check_minotaur(labyrinth_id:, engine: nil, **)
            raise ArgumentError, 'labyrinth_id is required' if labyrinth_id.nil?

            resolve_engine(engine).check_minotaur(labyrinth_id: labyrinth_id)
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] check_minotaur error: #{e.message}"
            { success: false, error: e.message }
          end

          def labyrinth_report(labyrinth_id:, engine: nil, **)
            raise ArgumentError, 'labyrinth_id is required' if labyrinth_id.nil?

            result = resolve_engine(engine).labyrinth_report(labyrinth_id: labyrinth_id)
            { success: true }.merge(result)
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] labyrinth_report error: #{e.message}"
            { success: false, error: e.message }
          end

          def list_labyrinths(engine: nil, **)
            result = resolve_engine(engine).list_labyrinths
            { success: true, labyrinths: result, count: result.size }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def delete_labyrinth(labyrinth_id:, engine: nil, **)
            raise ArgumentError, 'labyrinth_id is required' if labyrinth_id.nil?

            resolve_engine(engine).delete_labyrinth(labyrinth_id: labyrinth_id)
          rescue ArgumentError => e
            Legion::Logging.debug "[cognitive_labyrinth] delete_labyrinth error: #{e.message}"
            { success: false, error: e.message }
          end

          private

          def labyrinth_engine
            @labyrinth_engine ||= Helpers::LabyrinthEngine.new
          end

          def resolve_engine(engine)
            engine || labyrinth_engine
          end
        end
      end
    end
  end
end
