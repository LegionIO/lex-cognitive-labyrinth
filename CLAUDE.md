# lex-cognitive-labyrinth

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Maze-like problem space navigation engine. Models a cognitive labyrinth as a directed graph of typed nodes (corridors, junctions, dead ends, entrances, exits, minotaur lairs). The agent explores by moving between nodes, dropping breadcrumbs for backtracking, following Ariadne's thread toward the exit, and encountering the Minotaur (dangerous misconceptions) at specially typed nodes.

## Gem Info

- **Gem name**: `lex-cognitive-labyrinth`
- **Module**: `Legion::Extensions::CognitiveLabyrinth`
- **Version**: `0.1.0`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_labyrinth/
  version.rb
  client.rb
  helpers/
    constants.rb
    node.rb
    labyrinth.rb
    labyrinth_engine.rb
  runners/
    cognitive_labyrinth.rb
  actors/
    thread_walker.rb
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `NODE_TYPES` | `%i[corridor junction dead_end entrance exit minotaur_lair]` | Valid node type values |
| `MAX_LABYRINTHS` | `20` | Per-engine labyrinth capacity |
| `MAX_NODES` | `200` | Per-engine node capacity |
| `DEFAULT_DANGER_LEVEL` | `0.0` | Starting danger for non-minotaur nodes |
| `MINOTAUR_DANGER_LEVEL` | `0.9` | Danger applied to `minotaur_lair` nodes |
| `DEAD_END_COMPLEXITY_HIT` | `0.1` | Complexity added when entering a dead end |
| `COMPLEXITY_LABELS` | range hash | Labels from `:trivial` to `:impossible` |
| `DANGER_LABELS` | range hash | Labels from `:safe` to `:lethal` |

## Helpers

### `Helpers::Node`
Graph node with `id`, `label`, `node_type`, `connections` (array of neighbor IDs), and `danger_level`.

- `connect!(other_node_id)` — adds neighbor (idempotent)
- `disconnect!(other_node_id)` — removes neighbor
- `dead_end?` — true if `node_type == :dead_end`
- `junction?` — true if `node_type == :junction`
- `dangerous?` — true if `danger_level > 0.5`
- `to_h` — serializes to hash

### `Helpers::Labyrinth`
Single labyrinth instance. Holds nodes hash, current position, breadcrumb trail, and Ariadne's thread.

- `add_node(node)` — registers node
- `move_to!(node_id)` — changes current position, drops breadcrumb, increments dead-end complexity
- `backtrack!` — pops breadcrumb stack to return to previous node
- `drop_breadcrumb` — records current position in trail
- `follow_thread` — returns path toward exit node (thread set on entrance)
- `solved?` — current node is the exit
- `lost?` — no breadcrumbs and not at entrance
- `path_length` — breadcrumb count
- `complexity` / `complexity_label`
- `to_h`

### `Helpers::LabyrinthEngine`
Top-level in-memory store. Enforces `MAX_LABYRINTHS` and `MAX_NODES`.

- `create_labyrinth(name:)` → labyrinth or `{error: :capacity_exceeded}`
- `add_node_to(labyrinth_id:, label:, node_type:, danger_level:)` → node or error
- `connect_nodes(labyrinth_id:, from_id:, to_id:)` → status hash
- `move(labyrinth_id:, node_id:)` → position hash
- `backtrack(labyrinth_id:)` → position hash or `:at_entrance`
- `follow_thread(labyrinth_id:)` → thread path
- `check_minotaur(labyrinth_id:)` → danger result for current node
- `labyrinth_report(labyrinth_id:)` → full status hash
- `list_labyrinths` → array of labyrinth summaries
- `delete_labyrinth(labyrinth_id:)` → boolean

## Runners

Module: `Runners::CognitiveLaby rinth` (included via `Client`)

| Runner Method | Description |
|---|---|
| `create_labyrinth(name:)` | Create a new labyrinth |
| `add_node(labyrinth_id:, label:, node_type:, danger_level:)` | Add a node |
| `connect_nodes(labyrinth_id:, from_id:, to_id:)` | Connect two nodes |
| `move(labyrinth_id:, node_id:)` | Move current position |
| `backtrack(labyrinth_id:)` | Backtrack along breadcrumbs |
| `follow_thread(labyrinth_id:)` | Follow Ariadne's thread toward exit |
| `check_minotaur(labyrinth_id:)` | Check danger at current node |
| `labyrinth_report(labyrinth_id:)` | Full labyrinth state |
| `list_labyrinths` | All labyrinths summary |
| `delete_labyrinth(labyrinth_id:)` | Remove labyrinth |

All runners return `{success: true/false, ...}` hashes.

## Actors

### `Actors::ThreadWalker`
- Subclass of `Legion::Extensions::Actors::Every`
- Interval: `600` seconds
- Calls `Runners::CognitiveLaby rinth#list_labyrinths`
- `run_now? = false`, `use_runner? = false`
- Passive periodic survey of all open labyrinths

## Integration Points

- No direct dependencies on other agentic LEX gems
- Can integrate with `lex-tick` via `action_selection` phase handler to gate actions when the agent is "lost" in a problem space
- Works alongside `lex-memory` for persisting explored paths as semantic traces
- Minotaur encounters (high danger) can feed into `lex-emotion` arousal signal

## Development Notes

- `Client` instantiates `@labyrinth_engine = Helpers::LabyrinthEngine.new` — all state is per-client-instance
- Ariadne's thread is set at entrance node creation and points toward the exit node ID
- `backtrack!` returns `:at_entrance` when the breadcrumb stack is empty
- Node connections are directed (one-way unless connected in both directions)
- `MAX_LABYRINTHS` and `MAX_NODES` are enforced at engine level; runners receive error hashes on overflow
