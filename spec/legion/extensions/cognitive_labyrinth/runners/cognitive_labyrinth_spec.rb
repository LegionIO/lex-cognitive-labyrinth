# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLabyrinth::Runners::CognitiveLabyrinth do
  let(:engine) { Legion::Extensions::CognitiveLabyrinth::Helpers::LabyrinthEngine.new }

  let(:runner_host) do
    host = Object.new
    host.extend(described_class)
    host
  end

  let(:lab_id) do
    result = runner_host.create_labyrinth(name: 'Runner Test', engine: engine)
    result[:labyrinth_id]
  end

  describe '#create_labyrinth' do
    it 'returns success: true with labyrinth_id' do
      result = runner_host.create_labyrinth(name: 'My Maze', engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:labyrinth_id]).to be_a(String)
      expect(result[:name]).to eq('My Maze')
    end

    it 'returns success: false when name is empty' do
      result = runner_host.create_labyrinth(name: '', engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to be_a(String)
    end

    it 'returns success: false when name is nil' do
      result = runner_host.create_labyrinth(name: nil, engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'passes domain through' do
      result = runner_host.create_labyrinth(name: 'Typed', domain: :epistemology, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:domain]).to eq(:epistemology)
    end
  end

  describe '#add_node' do
    it 'adds a node and returns success: true' do
      result = runner_host.add_node(labyrinth_id: lab_id, node_type: :corridor, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:node_id]).to be_a(String)
      expect(result[:node_type]).to eq(:corridor)
    end

    it 'returns success: false when labyrinth_id is nil' do
      result = runner_host.add_node(labyrinth_id: nil, node_type: :corridor, engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'returns success: false when node_type is nil' do
      result = runner_host.add_node(labyrinth_id: lab_id, node_type: nil, engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'returns success: false for invalid node_type' do
      result = runner_host.add_node(labyrinth_id: lab_id, node_type: :dungeon, engine: engine)
      expect(result[:success]).to be(false)
    end
  end

  describe '#connect_nodes' do
    let(:from_id) do
      runner_host.add_node(labyrinth_id: lab_id, node_type: :entrance, engine: engine)[:node_id]
    end
    let(:to_id) do
      runner_host.add_node(labyrinth_id: lab_id, node_type: :corridor, engine: engine)[:node_id]
    end

    it 'connects two nodes' do
      result = runner_host.connect_nodes(labyrinth_id: lab_id, from_id: from_id, to_id: to_id, engine: engine)
      expect(result[:connected]).to be(true)
    end

    it 'returns success: false when labyrinth_id is nil' do
      result = runner_host.connect_nodes(labyrinth_id: nil, from_id: 'a', to_id: 'b', engine: engine)
      expect(result[:success]).to be(false)
    end
  end

  describe '#move' do
    before do
      runner_host.add_node(labyrinth_id: lab_id, node_type: :entrance, node_id: 'entrance', engine: engine)
      runner_host.add_node(labyrinth_id: lab_id, node_type: :corridor, node_id: 'corridor', engine: engine)
      runner_host.connect_nodes(labyrinth_id: lab_id, from_id: 'entrance', to_id: 'corridor', engine: engine)
    end

    it 'moves to a connected node' do
      result = runner_host.move(labyrinth_id: lab_id, node_id: 'corridor', engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:node_id]).to eq('corridor')
    end

    it 'returns success: false for disconnected node' do
      result = runner_host.move(labyrinth_id: lab_id, node_id: 'entrance', engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'returns success: false when labyrinth_id is nil' do
      result = runner_host.move(labyrinth_id: nil, node_id: 'x', engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'returns success: false when node_id is nil' do
      result = runner_host.move(labyrinth_id: lab_id, node_id: nil, engine: engine)
      expect(result[:success]).to be(false)
    end
  end

  describe '#backtrack' do
    before do
      runner_host.add_node(labyrinth_id: lab_id, node_type: :entrance, node_id: 'entrance', engine: engine)
      runner_host.add_node(labyrinth_id: lab_id, node_type: :corridor, node_id: 'corridor', engine: engine)
      runner_host.connect_nodes(labyrinth_id: lab_id, from_id: 'entrance', to_id: 'corridor', engine: engine)
      runner_host.move(labyrinth_id: lab_id, node_id: 'corridor', engine: engine)
    end

    it 'backtracks and returns success: true' do
      result = runner_host.backtrack(labyrinth_id: lab_id, engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns success: false when labyrinth_id is nil' do
      result = runner_host.backtrack(labyrinth_id: nil, engine: engine)
      expect(result[:success]).to be(false)
    end
  end

  describe '#follow_thread' do
    before do
      runner_host.add_node(labyrinth_id: lab_id, node_type: :entrance, node_id: 'entrance', engine: engine)
      runner_host.add_node(labyrinth_id: lab_id, node_type: :corridor, node_id: 'corridor', engine: engine)
      runner_host.connect_nodes(labyrinth_id: lab_id, from_id: 'entrance', to_id: 'corridor', engine: engine)
    end

    it 'follows Ariadne\'s thread to an unvisited node' do
      result = runner_host.follow_thread(labyrinth_id: lab_id, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:node_id]).to eq('corridor')
    end

    it 'returns success: false when labyrinth_id is nil' do
      result = runner_host.follow_thread(labyrinth_id: nil, engine: engine)
      expect(result[:success]).to be(false)
    end
  end

  describe '#check_minotaur' do
    before do
      runner_host.add_node(labyrinth_id: lab_id, node_type: :minotaur_lair, node_id: 'lair',
                           content: 'confirmation bias', engine: engine)
      engine.labyrinths[lab_id].instance_variable_set(:@current_node_id, 'lair')
    end

    it 'returns encountered: true for minotaur_lair' do
      result = runner_host.check_minotaur(labyrinth_id: lab_id, engine: engine)
      expect(result[:encountered]).to be(true)
      expect(result[:misconception]).to eq('confirmation bias')
    end

    it 'returns success: false when labyrinth_id is nil' do
      result = runner_host.check_minotaur(labyrinth_id: nil, engine: engine)
      expect(result[:success]).to be(false)
    end
  end

  describe '#labyrinth_report' do
    before do
      runner_host.add_node(labyrinth_id: lab_id, node_type: :entrance, engine: engine)
    end

    it 'returns success: true with report data' do
      result = runner_host.labyrinth_report(labyrinth_id: lab_id, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:labyrinth_id]).to eq(lab_id)
    end

    it 'returns success: false when labyrinth_id is nil' do
      result = runner_host.labyrinth_report(labyrinth_id: nil, engine: engine)
      expect(result[:success]).to be(false)
    end
  end

  describe '#list_labyrinths' do
    it 'returns a list of labyrinths' do
      result = runner_host.list_labyrinths(engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:labyrinths]).to be_an(Array)
      expect(result[:count]).to be_a(Integer)
    end
  end

  describe '#delete_labyrinth' do
    it 'deletes a labyrinth' do
      result = runner_host.delete_labyrinth(labyrinth_id: lab_id, engine: engine)
      expect(result[:deleted]).to be(true)
    end

    it 'returns success: false when labyrinth_id is nil' do
      result = runner_host.delete_labyrinth(labyrinth_id: nil, engine: engine)
      expect(result[:success]).to be(false)
    end
  end
end
