# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLabyrinth::Client do
  subject(:client) { described_class.new }

  it 'includes the CognitiveLabyrinth runner' do
    expect(client).to respond_to(:create_labyrinth)
    expect(client).to respond_to(:add_node)
    expect(client).to respond_to(:move)
    expect(client).to respond_to(:backtrack)
    expect(client).to respond_to(:follow_thread)
    expect(client).to respond_to(:check_minotaur)
    expect(client).to respond_to(:labyrinth_report)
    expect(client).to respond_to(:list_labyrinths)
    expect(client).to respond_to(:delete_labyrinth)
  end

  describe 'full labyrinth traversal scenario' do
    it 'creates, traverses, and solves a simple labyrinth' do
      # Create the labyrinth
      create_result = client.create_labyrinth(name: 'Gauntlet', domain: :logic)
      expect(create_result[:success]).to be(true)
      lab_id = create_result[:labyrinth_id]

      # Build the maze structure
      client.add_node(labyrinth_id: lab_id, node_type: :entrance, node_id: 'start')
      client.add_node(labyrinth_id: lab_id, node_type: :corridor, node_id: 'mid')
      client.add_node(labyrinth_id: lab_id, node_type: :dead_end, node_id: 'dead', content: 'no way out')
      client.add_node(labyrinth_id: lab_id, node_type: :minotaur_lair, node_id: 'lair', content: 'false dichotomy')
      client.add_node(labyrinth_id: lab_id, node_type: :exit, node_id: 'goal')

      # Wire connections
      client.connect_nodes(labyrinth_id: lab_id, from_id: 'start', to_id: 'mid')
      client.connect_nodes(labyrinth_id: lab_id, from_id: 'mid', to_id: 'dead', bidirectional: false)
      client.connect_nodes(labyrinth_id: lab_id, from_id: 'mid', to_id: 'lair', bidirectional: false)
      client.connect_nodes(labyrinth_id: lab_id, from_id: 'mid', to_id: 'goal')

      # Move through the maze
      move1 = client.move(labyrinth_id: lab_id, node_id: 'mid')
      expect(move1[:success]).to be(true)
      expect(move1[:solved]).to be(false)

      # Check minotaur from current position (mid — safe)
      minotaur = client.check_minotaur(labyrinth_id: lab_id)
      expect(minotaur[:encountered]).to be(false)

      # Move to exit
      move2 = client.move(labyrinth_id: lab_id, node_id: 'goal')
      expect(move2[:success]).to be(true)
      expect(move2[:solved]).to be(true)

      # Report
      report = client.labyrinth_report(labyrinth_id: lab_id)
      expect(report[:success]).to be(true)
      expect(report[:node_count]).to eq(5)
      expect(report[:nodes_by_type][:dead_end]).to eq(1)
      expect(report[:nodes_by_type][:minotaur_lair]).to eq(1)
    end

    it 'follows Ariadne\'s thread through a maze' do
      create_result = client.create_labyrinth(name: 'Thread Test')
      lab_id = create_result[:labyrinth_id]

      client.add_node(labyrinth_id: lab_id, node_type: :entrance, node_id: 'a')
      client.add_node(labyrinth_id: lab_id, node_type: :corridor, node_id: 'b')
      client.add_node(labyrinth_id: lab_id, node_type: :exit, node_id: 'c')
      client.connect_nodes(labyrinth_id: lab_id, from_id: 'a', to_id: 'b')
      client.connect_nodes(labyrinth_id: lab_id, from_id: 'b', to_id: 'c')

      t1 = client.follow_thread(labyrinth_id: lab_id)
      expect(t1[:success]).to be(true)
      expect(t1[:node_id]).to eq('b')

      t2 = client.follow_thread(labyrinth_id: lab_id)
      expect(t2[:success]).to be(true)
      expect(t2[:node_id]).to eq('c')
      expect(t2[:solved]).to be(true)
    end

    it 'backtracks after a dead end' do
      create_result = client.create_labyrinth(name: 'Backtrack Test')
      lab_id = create_result[:labyrinth_id]

      client.add_node(labyrinth_id: lab_id, node_type: :entrance, node_id: 'entry')
      client.add_node(labyrinth_id: lab_id, node_type: :dead_end, node_id: 'dead')
      client.connect_nodes(labyrinth_id: lab_id, from_id: 'entry', to_id: 'dead')

      client.move(labyrinth_id: lab_id, node_id: 'dead')
      back = client.backtrack(labyrinth_id: lab_id)
      expect(back[:success]).to be(true)
      expect(back[:node_id]).to eq('entry')
    end

    it 'detects minotaur when entering minotaur_lair' do
      create_result = client.create_labyrinth(name: 'Lair Test')
      lab_id = create_result[:labyrinth_id]

      client.add_node(labyrinth_id: lab_id, node_type: :entrance, node_id: 'start')
      client.add_node(labyrinth_id: lab_id, node_type: :minotaur_lair, node_id: 'lair', content: 'ad hominem')
      client.connect_nodes(labyrinth_id: lab_id, from_id: 'start', to_id: 'lair')

      move_result = client.move(labyrinth_id: lab_id, node_id: 'lair')
      expect(move_result[:minotaur][:encountered]).to be(true)
      expect(move_result[:minotaur][:misconception]).to eq('ad hominem')
    end
  end

  describe '#list_labyrinths' do
    it 'starts empty' do
      fresh = described_class.new
      result = fresh.list_labyrinths
      expect(result[:count]).to eq(0)
    end

    it 'counts created labyrinths' do
      client.create_labyrinth(name: 'Alpha')
      client.create_labyrinth(name: 'Beta')
      result = client.list_labyrinths
      expect(result[:count]).to eq(2)
    end
  end
end
