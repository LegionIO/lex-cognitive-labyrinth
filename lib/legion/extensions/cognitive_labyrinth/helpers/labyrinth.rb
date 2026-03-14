# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLabyrinth
      module Helpers
        class Labyrinth
          attr_reader :labyrinth_id, :name, :domain, :nodes, :breadcrumbs, :current_node_id
          attr_accessor :solved

          def initialize(labyrinth_id:, name:, domain: nil)
            @labyrinth_id   = labyrinth_id
            @name           = name
            @domain         = domain
            @nodes          = {}
            @breadcrumbs    = []
            @current_node_id = nil
            @solved          = false
          end

          def add_node(node)
            raise ArgumentError, "nodes must be a #{Node}" unless node.is_a?(Node)
            raise ArgumentError, "max nodes (#{Constants::MAX_NODES}) reached" if @nodes.size >= Constants::MAX_NODES

            @nodes[node.node_id] = node
            @current_node_id ||= node.node_id if node.node_type == :entrance
            node
          end

          def move_to!(node_id)
            node = @nodes.fetch(node_id) { raise ArgumentError, "node #{node_id.inspect} not found in labyrinth" }

            current = current_node
            unless current.nil? || current.connections.include?(node_id)
              raise ArgumentError, "cannot move to #{node_id.inspect}: not connected from current node #{@current_node_id.inspect}"
            end

            drop_breadcrumb
            node.visited = true
            @current_node_id = node_id
            @solved = true if node.node_type == :exit
            node
          end

          def backtrack!
            return nil if @breadcrumbs.empty?

            target_id = @breadcrumbs.pop
            @current_node_id = target_id
            current_node
          end

          def drop_breadcrumb
            return unless @current_node_id

            current = @nodes[@current_node_id]
            current.visited = true if current
            @breadcrumbs << @current_node_id if @breadcrumbs.last != @current_node_id
          end

          def follow_thread
            return nil if current_node.nil?

            unvisited = current_node.connections.find do |conn_id|
              node = @nodes[conn_id]
              node && !node.visited
            end

            return nil unless unvisited

            move_to!(unvisited)
          end

          def solved?
            @solved
          end

          def lost?
            return false if @current_node_id.nil?
            return false if solved?

            current = current_node
            return true if current.nil?

            unvisited_exits = current.connections.any? do |conn_id|
              node = @nodes[conn_id]
              node && !node.visited
            end

            !unvisited_exits && !current.dead_end? && @breadcrumbs.empty?
          end

          def path_length
            @breadcrumbs.size
          end

          def current_node
            @nodes[@current_node_id]
          end

          def complexity
            return 0.0 if @nodes.empty?

            dead_end_count  = @nodes.values.count(&:dead_end?)
            junction_count  = @nodes.values.count(&:junction?)
            minotaur_count  = @nodes.values.count { |n| n.node_type == :minotaur_lair }

            raw = ((dead_end_count * 0.3) + (junction_count * 0.2) + (minotaur_count * 0.5)) / @nodes.size.to_f
            raw.clamp(0.0, 1.0).round(10)
          end

          def complexity_label
            score = complexity
            Constants::COMPLEXITY_LABELS.find { |range, _| range.cover?(score) }&.last || :labyrinthine
          end

          def to_h
            {
              labyrinth_id:     @labyrinth_id,
              name:             @name,
              domain:           @domain,
              node_count:       @nodes.size,
              current_node_id:  @current_node_id,
              path_length:      path_length,
              solved:           @solved,
              complexity:       complexity,
              complexity_label: complexity_label
            }
          end
        end
      end
    end
  end
end
