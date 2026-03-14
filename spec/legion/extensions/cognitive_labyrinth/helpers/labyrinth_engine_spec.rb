# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLabyrinth::Helpers::LabyrinthEngine do
  subject(:engine) { described_class.new }

  let(:lab_id) do
    result = engine.create_labyrinth(name: 'Test Maze')
    result.labyrinth_id
  end

  describe '#create_labyrinth' do
    it 'creates a new labyrinth and returns it' do
      lab = engine.create_labyrinth(name: 'Puzzle', domain: :logic)
      expect(lab).to be_a(Legion::Extensions::CognitiveLabyrinth::Helpers::Labyrinth)
      expect(lab.name).to eq('Puzzle')
      expect(lab.domain).to eq(:logic)
    end

    it 'uses provided labyrinth_id' do
      lab = engine.create_labyrinth(name: 'Custom', labyrinth_id: 'my-id')
      expect(lab.labyrinth_id).to eq('my-id')
    end

    it 'generates a UUID when labyrinth_id is not provided' do
      lab = engine.create_labyrinth(name: 'Auto')
      expect(lab.labyrinth_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'raises ArgumentError at MAX_LABYRINTHS' do
      max = Legion::Extensions::CognitiveLabyrinth::Helpers::Constants::MAX_LABYRINTHS
      max.times { |i| engine.create_labyrinth(name: "lab #{i}") }
      expect { engine.create_labyrinth(name: 'overflow') }.to raise_error(ArgumentError, /max labyrinths/)
    end

    it 'stores the labyrinth in @labyrinths' do
      lab = engine.create_labyrinth(name: 'Stored')
      expect(engine.labyrinths[lab.labyrinth_id]).to eq(lab)
    end
  end

  describe '#add_node_to' do
    it 'adds a corridor node' do
      node = engine.add_node_to(labyrinth_id: lab_id, node_type: :corridor, content: 'a dark hallway')
      expect(node.node_type).to eq(:corridor)
      expect(node.content).to eq('a dark hallway')
    end

    it 'auto-assigns danger level for minotaur_lair' do
      node = engine.add_node_to(labyrinth_id: lab_id, node_type: :minotaur_lair)
      expect(node.danger_level).to eq(Legion::Extensions::CognitiveLabyrinth::Helpers::Constants::MINOTAUR_DANGER_LEVEL)
    end

    it 'uses provided node_id' do
      node = engine.add_node_to(labyrinth_id: lab_id, node_type: :corridor, node_id: 'fixed-id')
      expect(node.node_id).to eq('fixed-id')
    end

    it 'raises ArgumentError for unknown labyrinth' do
      expect do
        engine.add_node_to(labyrinth_id: 'nonexistent', node_type: :corridor)
      end.to raise_error(ArgumentError, /not found/)
    end
  end

  describe '#connect_nodes' do
    let(:from_id) { engine.add_node_to(labyrinth_id: lab_id, node_type: :entrance).node_id }
    let(:to_id) { engine.add_node_to(labyrinth_id: lab_id, node_type: :corridor).node_id }

    it 'connects two nodes bidirectionally by default' do
      engine.connect_nodes(labyrinth_id: lab_id, from_id: from_id, to_id: to_id)
      lab = engine.labyrinths[lab_id]
      expect(lab.nodes[from_id].connections).to include(to_id)
      expect(lab.nodes[to_id].connections).to include(from_id)
    end

    it 'connects one-way when bidirectional: false' do
      engine.connect_nodes(labyrinth_id: lab_id, from_id: from_id, to_id: to_id, bidirectional: false)
      lab = engine.labyrinths[lab_id]
      expect(lab.nodes[from_id].connections).to include(to_id)
      expect(lab.nodes[to_id].connections).not_to include(from_id)
    end

    it 'returns a result hash' do
      result = engine.connect_nodes(labyrinth_id: lab_id, from_id: from_id, to_id: to_id)
      expect(result[:connected]).to be(true)
      expect(result[:from]).to eq(from_id)
      expect(result[:to]).to eq(to_id)
    end
  end

  describe '#move' do
    before do
      engine.add_node_to(labyrinth_id: lab_id, node_type: :entrance, node_id: 'entrance')
      engine.add_node_to(labyrinth_id: lab_id, node_type: :corridor, node_id: 'corridor')
      engine.connect_nodes(labyrinth_id: lab_id, from_id: 'entrance', to_id: 'corridor')
    end

    it 'moves to a connected node and returns result hash' do
      result = engine.move(labyrinth_id: lab_id, node_id: 'corridor')
      expect(result[:success]).to be(true)
      expect(result[:node_id]).to eq('corridor')
      expect(result[:node_type]).to eq(:corridor)
      expect(result[:path_length]).to eq(1)
    end

    it 'includes minotaur check result' do
      result = engine.move(labyrinth_id: lab_id, node_id: 'corridor')
      expect(result[:minotaur]).to be_a(Hash)
      expect(result[:minotaur][:encountered]).to be(false)
    end
  end

  describe '#backtrack' do
    before do
      engine.add_node_to(labyrinth_id: lab_id, node_type: :entrance, node_id: 'entrance')
      engine.add_node_to(labyrinth_id: lab_id, node_type: :corridor, node_id: 'corridor')
      engine.connect_nodes(labyrinth_id: lab_id, from_id: 'entrance', to_id: 'corridor')
      engine.move(labyrinth_id: lab_id, node_id: 'corridor')
    end

    it 'backtracks to previous node' do
      result = engine.backtrack(labyrinth_id: lab_id)
      expect(result[:success]).to be(true)
      expect(result[:node_id]).to eq('entrance')
    end

    it 'returns failure when no breadcrumbs' do
      engine.backtrack(labyrinth_id: lab_id)
      result = engine.backtrack(labyrinth_id: lab_id)
      expect(result[:success]).to be(false)
      expect(result[:reason]).to eq(:no_breadcrumbs)
    end
  end

  describe '#follow_thread' do
    before do
      engine.add_node_to(labyrinth_id: lab_id, node_type: :entrance, node_id: 'entrance')
      engine.add_node_to(labyrinth_id: lab_id, node_type: :corridor, node_id: 'corridor')
      engine.connect_nodes(labyrinth_id: lab_id, from_id: 'entrance', to_id: 'corridor')
    end

    it 'follows to the first unvisited node' do
      result = engine.follow_thread(labyrinth_id: lab_id)
      expect(result[:success]).to be(true)
      expect(result[:node_id]).to eq('corridor')
    end

    it 'returns thread_exhausted when nothing unvisited' do
      engine.labyrinths[lab_id].nodes['corridor'].visited = true
      result = engine.follow_thread(labyrinth_id: lab_id)
      expect(result[:success]).to be(false)
      expect(result[:reason]).to eq(:thread_exhausted)
    end
  end

  describe '#check_minotaur' do
    before do
      engine.add_node_to(labyrinth_id: lab_id, node_type: :minotaur_lair, node_id: 'lair', content: 'sunk cost fallacy')
    end

    it 'returns encountered: true when on minotaur_lair' do
      engine.labyrinths[lab_id].instance_variable_set(:@current_node_id, 'lair')
      result = engine.check_minotaur(labyrinth_id: lab_id)
      expect(result[:encountered]).to be(true)
      expect(result[:misconception]).to eq('sunk cost fallacy')
      expect(result[:danger_label]).to be_a(Symbol)
    end

    it 'returns encountered: false for safe node' do
      engine.add_node_to(labyrinth_id: lab_id, node_type: :corridor, node_id: 'safe')
      engine.labyrinths[lab_id].instance_variable_set(:@current_node_id, 'safe')
      result = engine.check_minotaur(labyrinth_id: lab_id)
      expect(result[:encountered]).to be(false)
    end
  end

  describe '#labyrinth_report' do
    before do
      engine.add_node_to(labyrinth_id: lab_id, node_type: :entrance, node_id: 'entrance')
      engine.add_node_to(labyrinth_id: lab_id, node_type: :dead_end, node_id: 'dead')
      engine.add_node_to(labyrinth_id: lab_id, node_type: :exit, node_id: 'exit')
    end

    it 'returns a comprehensive report hash' do
      report = engine.labyrinth_report(labyrinth_id: lab_id)
      expect(report).to include(:labyrinth_id, :name, :node_count, :nodes_by_type, :visited_count, :breadcrumb_trail, :lost)
    end

    it 'includes nodes_by_type breakdown' do
      report = engine.labyrinth_report(labyrinth_id: lab_id)
      expect(report[:nodes_by_type]).to include(entrance: 1, dead_end: 1, exit: 1)
    end
  end

  describe '#list_labyrinths' do
    it 'returns empty array initially' do
      fresh = described_class.new
      expect(fresh.list_labyrinths).to eq([])
    end

    it 'lists all created labyrinths' do
      fresh = described_class.new
      fresh.create_labyrinth(name: 'A')
      fresh.create_labyrinth(name: 'B')
      list = fresh.list_labyrinths
      expect(list.size).to eq(2)
      expect(list.map { |l| l[:name] }).to include('A', 'B')
    end
  end

  describe '#delete_labyrinth' do
    it 'removes the labyrinth' do
      result = engine.delete_labyrinth(labyrinth_id: lab_id)
      expect(result[:deleted]).to be(true)
      expect(engine.labyrinths).not_to have_key(lab_id)
    end

    it 'raises ArgumentError for unknown labyrinth' do
      expect { engine.delete_labyrinth(labyrinth_id: 'nope') }.to raise_error(ArgumentError, /not found/)
    end
  end
end
