# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLabyrinth::Helpers::Constants do
  describe 'NODE_TYPES' do
    it 'includes all expected node types' do
      expected = %i[corridor junction dead_end entrance exit minotaur_lair]
      expect(described_class::NODE_TYPES).to eq(expected)
    end

    it 'is frozen' do
      expect(described_class::NODE_TYPES).to be_frozen
    end
  end

  describe 'MAX_LABYRINTHS' do
    it 'is a positive integer' do
      expect(described_class::MAX_LABYRINTHS).to be_a(Integer)
      expect(described_class::MAX_LABYRINTHS).to be_positive
    end
  end

  describe 'MAX_NODES' do
    it 'is a positive integer' do
      expect(described_class::MAX_NODES).to be_a(Integer)
      expect(described_class::MAX_NODES).to be_positive
    end
  end

  describe 'COMPLEXITY_LABELS' do
    it 'covers the full 0..1 range' do
      [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0].each do |score|
        match = described_class::COMPLEXITY_LABELS.any? { |range, _| range.cover?(score) }
        expect(match).to be(true), "score #{score} not covered by COMPLEXITY_LABELS"
      end
    end

    it 'maps low scores to :trivial' do
      label = described_class::COMPLEXITY_LABELS.find { |r, _| r.cover?(0.05) }&.last
      expect(label).to eq(:trivial)
    end

    it 'maps high scores to :labyrinthine' do
      label = described_class::COMPLEXITY_LABELS.find { |r, _| r.cover?(0.95) }&.last
      expect(label).to eq(:labyrinthine)
    end
  end

  describe 'DANGER_LABELS' do
    it 'covers the full 0..1 range' do
      [0.0, 0.24, 0.3, 0.6, 0.8, 1.0].each do |level|
        match = described_class::DANGER_LABELS.any? { |range, _| range.cover?(level) }
        expect(match).to be(true), "level #{level} not covered by DANGER_LABELS"
      end
    end

    it 'maps low danger to :safe' do
      label = described_class::DANGER_LABELS.find { |r, _| r.cover?(0.1) }&.last
      expect(label).to eq(:safe)
    end

    it 'maps high danger to :lethal' do
      label = described_class::DANGER_LABELS.find { |r, _| r.cover?(0.9) }&.last
      expect(label).to eq(:lethal)
    end
  end

  describe 'MINOTAUR_DANGER_LEVEL' do
    it 'is >= 0.5' do
      expect(described_class::MINOTAUR_DANGER_LEVEL).to be >= 0.5
    end
  end
end
