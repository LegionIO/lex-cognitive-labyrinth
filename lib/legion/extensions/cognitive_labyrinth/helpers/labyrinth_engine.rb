# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLabyrinth
      module Helpers
        class LabyrinthEngine
          attr_reader :labyrinths

          def initialize
            @labyrinths = {}
          end

          def create_labyrinth(name:, domain: nil, labyrinth_id: nil)
            raise ArgumentError, "max labyrinths (#{Constants::MAX_LABYRINTHS}) reached" if @labyrinths.size >= Constants::MAX_LABYRINTHS

            id = labyrinth_id || SecureRandom.uuid
            labyrinth = Labyrinth.new(labyrinth_id: id, name: name, domain: domain)
            @labyrinths[id] = labyrinth
            Legion::Logging.debug "[cognitive_labyrinth] created labyrinth id=#{id[0..7]} name=#{name}"
            labyrinth
          end

          def add_node_to(labyrinth_id:, node_type:, content: nil, danger_level: nil, node_id: nil)
            labyrinth = fetch_labyrinth!(labyrinth_id)
            id        = node_id || SecureRandom.uuid
            level     = (danger_level || default_danger_for(node_type)).clamp(0.0, 1.0)

            node = Node.new(node_id: id, node_type: node_type, content: content, danger_level: level)
            labyrinth.add_node(node)
            Legion::Logging.debug "[cognitive_labyrinth] added node #{id[0..7]} type=#{node_type} to labyrinth #{labyrinth_id[0..7]}"
            node
          end

          def connect_nodes(labyrinth_id:, from_id:, to_id:, bidirectional: true)
            labyrinth  = fetch_labyrinth!(labyrinth_id)
            from_node  = fetch_node!(labyrinth, from_id)
            to_node    = fetch_node!(labyrinth, to_id)

            from_node.connect!(to_id)
            to_node.connect!(from_id) if bidirectional
            { connected: true, from: from_id, to: to_id, bidirectional: bidirectional }
          end

          def move(labyrinth_id:, node_id:, **)
            labyrinth = fetch_labyrinth!(labyrinth_id)
            node      = labyrinth.move_to!(node_id)

            minotaur_result = check_minotaur(labyrinth_id: labyrinth_id)
            Legion::Logging.debug "[cognitive_labyrinth] moved to #{node_id[0..7]} type=#{node.node_type}"

            {
              success:      true,
              node_id:      node.node_id,
              node_type:    node.node_type,
              content:      node.content,
              danger_level: node.danger_level,
              solved:       labyrinth.solved?,
              minotaur:     minotaur_result,
              path_length:  labyrinth.path_length
            }
          end

          def backtrack(labyrinth_id:, **)
            labyrinth = fetch_labyrinth!(labyrinth_id)
            node      = labyrinth.backtrack!

            if node
              Legion::Logging.debug "[cognitive_labyrinth] backtracked to #{node.node_id[0..7]}"
              { success: true, node_id: node.node_id, node_type: node.node_type, path_length: labyrinth.path_length }
            else
              Legion::Logging.debug '[cognitive_labyrinth] backtrack failed: no breadcrumbs'
              { success: false, reason: :no_breadcrumbs }
            end
          end

          def follow_thread(labyrinth_id:, **)
            labyrinth = fetch_labyrinth!(labyrinth_id)
            node      = labyrinth.follow_thread

            if node
              minotaur_result = check_minotaur(labyrinth_id: labyrinth_id)
              Legion::Logging.debug "[cognitive_labyrinth] thread followed to #{node.node_id[0..7]}"
              {
                success:      true,
                node_id:      node.node_id,
                node_type:    node.node_type,
                content:      node.content,
                danger_level: node.danger_level,
                solved:       labyrinth.solved?,
                minotaur:     minotaur_result
              }
            else
              Legion::Logging.debug '[cognitive_labyrinth] thread exhausted: no unvisited nodes from current'
              { success: false, reason: :thread_exhausted }
            end
          end

          def check_minotaur(labyrinth_id:, **)
            labyrinth = fetch_labyrinth!(labyrinth_id)
            node      = labyrinth.current_node
            return { encountered: false } unless node

            if node.node_type == :minotaur_lair
              Legion::Logging.debug "[cognitive_labyrinth] MINOTAUR ENCOUNTERED at #{node.node_id[0..7]}"
              {
                encountered:   true,
                node_id:       node.node_id,
                danger_level:  node.danger_level,
                danger_label:  danger_label_for(node.danger_level),
                misconception: node.content
              }
            elsif node.dangerous?
              {
                encountered:  false,
                warning:      true,
                danger_level: node.danger_level,
                danger_label: danger_label_for(node.danger_level)
              }
            else
              { encountered: false }
            end
          end

          def labyrinth_report(labyrinth_id:, **)
            labyrinth = fetch_labyrinth!(labyrinth_id)
            nodes_by_type = labyrinth.nodes.values.group_by(&:node_type).transform_values(&:count)

            labyrinth.to_h.merge(
              nodes_by_type:    nodes_by_type,
              visited_count:    labyrinth.nodes.values.count(&:visited),
              breadcrumb_trail: labyrinth.breadcrumbs.dup,
              lost:             labyrinth.lost?
            )
          end

          def list_labyrinths(**)
            @labyrinths.values.map(&:to_h)
          end

          def delete_labyrinth(labyrinth_id:, **)
            raise ArgumentError, "labyrinth #{labyrinth_id.inspect} not found" unless @labyrinths.key?(labyrinth_id)

            @labyrinths.delete(labyrinth_id)
            { deleted: true, labyrinth_id: labyrinth_id }
          end

          private

          def fetch_labyrinth!(labyrinth_id)
            @labyrinths.fetch(labyrinth_id) do
              raise ArgumentError, "labyrinth #{labyrinth_id.inspect} not found"
            end
          end

          def fetch_node!(labyrinth, node_id)
            labyrinth.nodes.fetch(node_id) do
              raise ArgumentError, "node #{node_id.inspect} not found in labyrinth #{labyrinth.labyrinth_id.inspect}"
            end
          end

          def default_danger_for(node_type)
            node_type == :minotaur_lair ? Constants::MINOTAUR_DANGER_LEVEL : Constants::DEFAULT_DANGER_LEVEL
          end

          def danger_label_for(level)
            Constants::DANGER_LABELS.find { |range, _| range.cover?(level) }&.last || :lethal
          end
        end
      end
    end
  end
end
