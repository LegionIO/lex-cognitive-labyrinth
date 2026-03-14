# lex-cognitive-labyrinth

Maze-like problem space navigation for LegionIO cognitive agents. Models complex reasoning challenges as labyrinths with typed nodes, directional connections, breadcrumb backtracking, and Ariadne's thread guidance toward the exit.

## What It Does

- Creates named labyrinths as directed graphs of cognitive nodes
- Node types: `corridor`, `junction`, `dead_end`, `entrance`, `exit`, `minotaur_lair`
- Navigation: move to nodes, drop breadcrumbs, backtrack along the crumb trail
- Ariadne's thread: pre-computed guidance path toward the exit node
- Minotaur detection: checks danger level at current position (minotaur lairs default to 0.9 danger)
- Complexity tracking: increases when entering dead ends
- Periodic survey via `ThreadWalker` actor (every 600s)

## Usage

```ruby
# Create a labyrinth
result = runner.create_labyrinth(name: 'problem_analysis')
labyrinth_id = result[:labyrinth][:id]

# Add nodes
entrance = runner.add_node(labyrinth_id: labyrinth_id, label: 'start', node_type: :entrance, danger_level: 0.0)
junction = runner.add_node(labyrinth_id: labyrinth_id, label: 'fork', node_type: :junction, danger_level: 0.0)
danger   = runner.add_node(labyrinth_id: labyrinth_id, label: 'false assumption', node_type: :minotaur_lair, danger_level: 0.9)
exit_n   = runner.add_node(labyrinth_id: labyrinth_id, label: 'solution', node_type: :exit, danger_level: 0.0)

# Connect and navigate
runner.connect_nodes(labyrinth_id: labyrinth_id, from_id: entrance[:node][:id], to_id: junction[:node][:id])
runner.move(labyrinth_id: labyrinth_id, node_id: junction[:node][:id])

# Check for danger
runner.check_minotaur(labyrinth_id: labyrinth_id)
# => { success: true, danger_level: 0.0, dangerous: false, ... }

# Backtrack if stuck
runner.backtrack(labyrinth_id: labyrinth_id)

# Follow the thread toward exit
runner.follow_thread(labyrinth_id: labyrinth_id)

# Full status
runner.labyrinth_report(labyrinth_id: labyrinth_id)
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
