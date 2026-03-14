# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLabyrinth::Helpers::Labyrinth do
  let(:labyrinth_id) { 'lab-001' }
  let(:labyrinth) { described_class.new(labyrinth_id: labyrinth_id, name: 'Test Maze', domain: :reasoning) }

  let(:node_class) { Legion::Extensions::CognitiveLabyrinth::Helpers::Node }

  def make_node(id, type, **)
    node_class.new(node_id: id, node_type: type, **)
  end

  describe '#initialize' do
    it 'creates a labyrinth with correct attributes' do
      expect(labyrinth.labyrinth_id).to eq(labyrinth_id)
      expect(labyrinth.name).to eq('Test Maze')
      expect(labyrinth.domain).to eq(:reasoning)
      expect(labyrinth.nodes).to eq({})
      expect(labyrinth.breadcrumbs).to eq([])
      expect(labyrinth.current_node_id).to be_nil
      expect(labyrinth.solved).to be(false)
    end
  end

  describe '#add_node' do
    it 'adds a node to the labyrinth' do
      node = make_node('n1', :corridor)
      labyrinth.add_node(node)
      expect(labyrinth.nodes['n1']).to eq(node)
    end

    it 'sets current_node_id to entrance node' do
      entrance = make_node('entrance-1', :entrance)
      labyrinth.add_node(entrance)
      expect(labyrinth.current_node_id).to eq('entrance-1')
    end

    it 'does not override current_node_id once set' do
      entrance = make_node('entrance-1', :entrance)
      entrance2 = make_node('entrance-2', :entrance)
      labyrinth.add_node(entrance)
      labyrinth.add_node(entrance2)
      expect(labyrinth.current_node_id).to eq('entrance-1')
    end

    it 'raises ArgumentError for non-Node argument' do
      expect { labyrinth.add_node('not a node') }.to raise_error(ArgumentError, /must be a/)
    end

    it 'raises ArgumentError when MAX_NODES exceeded' do
      max = Legion::Extensions::CognitiveLabyrinth::Helpers::Constants::MAX_NODES
      max.times { |i| labyrinth.add_node(make_node("n#{i}", :corridor)) }
      expect { labyrinth.add_node(make_node('overflow', :corridor)) }.to raise_error(ArgumentError, /max nodes/)
    end
  end

  describe '#move_to!' do
    before do
      entrance = make_node('entrance', :entrance)
      corridor = make_node('corridor', :corridor)
      exit_node = make_node('exit', :exit)
      entrance.connect!('corridor')
      corridor.connect!('entrance')
      corridor.connect!('exit')
      exit_node.connect!('corridor')
      labyrinth.add_node(entrance)
      labyrinth.add_node(corridor)
      labyrinth.add_node(exit_node)
    end

    it 'moves to a connected node' do
      labyrinth.move_to!('corridor')
      expect(labyrinth.current_node_id).to eq('corridor')
    end

    it 'marks the target node as visited' do
      labyrinth.move_to!('corridor')
      expect(labyrinth.nodes['corridor'].visited).to be(true)
    end

    it 'drops a breadcrumb on the previous node' do
      labyrinth.move_to!('corridor')
      expect(labyrinth.breadcrumbs).to include('entrance')
    end

    it 'sets solved when moving to exit' do
      labyrinth.move_to!('corridor')
      labyrinth.move_to!('exit')
      expect(labyrinth.solved?).to be(true)
    end

    it 'raises ArgumentError for unknown node_id' do
      expect { labyrinth.move_to!('unknown') }.to raise_error(ArgumentError, /not found/)
    end

    it 'raises ArgumentError when not connected' do
      expect { labyrinth.move_to!('exit') }.to raise_error(ArgumentError, /not connected/)
    end
  end

  describe '#backtrack!' do
    before do
      entrance = make_node('entrance', :entrance)
      corridor = make_node('corridor', :corridor)
      entrance.connect!('corridor')
      corridor.connect!('entrance')
      labyrinth.add_node(entrance)
      labyrinth.add_node(corridor)
      labyrinth.move_to!('corridor')
    end

    it 'returns nil when no breadcrumbs' do
      empty_lab = described_class.new(labyrinth_id: 'x', name: 'x')
      expect(empty_lab.backtrack!).to be_nil
    end

    it 'moves back to the previous node' do
      labyrinth.backtrack!
      expect(labyrinth.current_node_id).to eq('entrance')
    end
  end

  describe '#follow_thread' do
    before do
      entrance = make_node('entrance', :entrance)
      corridor = make_node('corridor', :corridor)
      entrance.connect!('corridor')
      corridor.connect!('entrance')
      labyrinth.add_node(entrance)
      labyrinth.add_node(corridor)
    end

    it 'moves to the first unvisited connected node' do
      result = labyrinth.follow_thread
      expect(result).not_to be_nil
      expect(labyrinth.current_node_id).to eq('corridor')
    end

    it 'returns nil when all connections are visited' do
      labyrinth.nodes['corridor'].visited = true
      result = labyrinth.follow_thread
      expect(result).to be_nil
    end

    it 'returns nil when current node is nil' do
      empty_lab = described_class.new(labyrinth_id: 'x', name: 'x')
      expect(empty_lab.follow_thread).to be_nil
    end
  end

  describe '#path_length' do
    it 'returns 0 when no moves made' do
      expect(labyrinth.path_length).to eq(0)
    end

    it 'returns breadcrumb count' do
      entrance = make_node('entrance', :entrance)
      corridor = make_node('corridor', :corridor)
      entrance.connect!('corridor')
      corridor.connect!('entrance')
      labyrinth.add_node(entrance)
      labyrinth.add_node(corridor)
      labyrinth.move_to!('corridor')
      expect(labyrinth.path_length).to eq(1)
    end
  end

  describe '#complexity' do
    it 'returns 0.0 for empty labyrinth' do
      expect(labyrinth.complexity).to eq(0.0)
    end

    it 'is higher with more dead ends and minotaur lairs' do
      labyrinth.add_node(make_node('d1', :dead_end))
      labyrinth.add_node(make_node('d2', :dead_end))
      labyrinth.add_node(make_node('m1', :minotaur_lair))
      expect(labyrinth.complexity).to be > 0.0
    end

    it 'is clamped between 0.0 and 1.0' do
      labyrinth.add_node(make_node('m1', :minotaur_lair))
      expect(labyrinth.complexity).to be_between(0.0, 1.0)
    end

    it 'rounds to 10 decimal places' do
      labyrinth.add_node(make_node('n1', :corridor))
      expect(labyrinth.complexity.to_s.split('.').last.to_s.length).to be <= 10
    end
  end

  describe '#complexity_label' do
    it 'returns a symbol' do
      labyrinth.add_node(make_node('n1', :corridor))
      expect(labyrinth.complexity_label).to be_a(Symbol)
    end

    it 'returns :trivial for a labyrinth with only well-connected corridors' do
      # A junction connected to several corridors — no dead ends, no minotaurs
      j = make_node('j', :junction)
      c1 = make_node('c1', :corridor)
      c2 = make_node('c2', :corridor)
      c3 = make_node('c3', :corridor)
      j.connect!('c1')
      j.connect!('c2')
      j.connect!('c3')
      c1.connect!('j')
      c2.connect!('j')
      c3.connect!('j')
      labyrinth.add_node(j)
      labyrinth.add_node(c1)
      labyrinth.add_node(c2)
      labyrinth.add_node(c3)
      expect(labyrinth.complexity_label).to eq(:trivial)
    end
  end

  describe '#solved?' do
    it 'returns false by default' do
      expect(labyrinth.solved?).to be(false)
    end
  end

  describe '#lost?' do
    it 'returns false with no current node' do
      expect(labyrinth.lost?).to be(false)
    end
  end

  describe '#to_h' do
    it 'includes expected keys' do
      h = labyrinth.to_h
      expect(h).to include(:labyrinth_id, :name, :domain, :node_count, :current_node_id, :path_length, :solved, :complexity, :complexity_label)
    end
  end
end
