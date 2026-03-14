# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLabyrinth::Helpers::Node do
  let(:node_id) { 'node-001' }

  describe '#initialize' do
    it 'creates a corridor node' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      expect(node.node_id).to eq(node_id)
      expect(node.node_type).to eq(:corridor)
      expect(node.visited).to be(false)
      expect(node.connections).to eq([])
      expect(node.danger_level).to eq(0.0)
    end

    it 'creates a minotaur_lair node' do
      node = described_class.new(node_id: node_id, node_type: :minotaur_lair, content: 'false belief')
      expect(node.node_type).to eq(:minotaur_lair)
      expect(node.content).to eq('false belief')
    end

    it 'clamps danger_level to 0..1' do
      node = described_class.new(node_id: node_id, node_type: :corridor, danger_level: 2.5)
      expect(node.danger_level).to eq(1.0)

      node2 = described_class.new(node_id: node_id, node_type: :corridor, danger_level: -1.0)
      expect(node2.danger_level).to eq(0.0)
    end

    it 'raises ArgumentError for unknown node_type' do
      expect do
        described_class.new(node_id: node_id, node_type: :dungeon)
      end.to raise_error(ArgumentError, /unknown node_type/)
    end

    it 'accepts all valid node types' do
      Legion::Extensions::CognitiveLabyrinth::Helpers::Constants::NODE_TYPES.each do |type|
        expect { described_class.new(node_id: "n-#{type}", node_type: type) }.not_to raise_error
      end
    end
  end

  describe '#connect!' do
    it 'adds a connection' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      node.connect!('other-node')
      expect(node.connections).to include('other-node')
    end

    it 'does not duplicate connections' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      node.connect!('other-node')
      node.connect!('other-node')
      expect(node.connections.count('other-node')).to eq(1)
    end

    it 'returns self for chaining' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      expect(node.connect!('other')).to eq(node)
    end
  end

  describe '#disconnect!' do
    it 'removes a connection' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      node.connect!('other-node')
      node.disconnect!('other-node')
      expect(node.connections).not_to include('other-node')
    end

    it 'returns self for chaining' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      expect(node.disconnect!('nonexistent')).to eq(node)
    end
  end

  describe '#dead_end?' do
    it 'returns true for :dead_end type' do
      node = described_class.new(node_id: node_id, node_type: :dead_end)
      expect(node.dead_end?).to be(true)
    end

    it 'returns true for corridor with no connections' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      expect(node.dead_end?).to be(true)
    end

    it 'returns false for corridor with connections' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      node.connect!('somewhere')
      expect(node.dead_end?).to be(false)
    end

    it 'returns false for entrance with no connections' do
      node = described_class.new(node_id: node_id, node_type: :entrance)
      expect(node.dead_end?).to be(false)
    end

    it 'returns false for exit with no connections' do
      node = described_class.new(node_id: node_id, node_type: :exit)
      expect(node.dead_end?).to be(false)
    end
  end

  describe '#junction?' do
    it 'returns true for :junction type' do
      node = described_class.new(node_id: node_id, node_type: :junction)
      expect(node.junction?).to be(true)
    end

    it 'returns true for corridor with 3+ connections' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      node.connect!('a')
      node.connect!('b')
      node.connect!('c')
      expect(node.junction?).to be(true)
    end

    it 'returns false for corridor with 2 connections' do
      node = described_class.new(node_id: node_id, node_type: :corridor)
      node.connect!('a')
      node.connect!('b')
      expect(node.junction?).to be(false)
    end
  end

  describe '#dangerous?' do
    it 'returns true for :minotaur_lair type' do
      node = described_class.new(node_id: node_id, node_type: :minotaur_lair)
      expect(node.dangerous?).to be(true)
    end

    it 'returns true for danger_level >= 0.5' do
      node = described_class.new(node_id: node_id, node_type: :corridor, danger_level: 0.5)
      expect(node.dangerous?).to be(true)
    end

    it 'returns false for safe corridor' do
      node = described_class.new(node_id: node_id, node_type: :corridor, danger_level: 0.2)
      expect(node.dangerous?).to be(false)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      node = described_class.new(node_id: node_id, node_type: :junction, content: 'crossroads', danger_level: 0.3)
      node.connect!('n2')
      h = node.to_h
      expect(h[:node_id]).to eq(node_id)
      expect(h[:node_type]).to eq(:junction)
      expect(h[:content]).to eq('crossroads')
      expect(h[:connections]).to eq(['n2'])
      expect(h[:visited]).to be(false)
      expect(h[:danger_level]).to eq(0.3)
    end
  end
end
