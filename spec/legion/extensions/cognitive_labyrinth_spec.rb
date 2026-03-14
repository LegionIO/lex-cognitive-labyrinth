# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveLabyrinth do
  it 'has a VERSION constant' do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it 'exposes the Client class' do
    expect(described_class::Client).to be_a(Class)
  end

  it 'exposes the Helpers namespace' do
    expect(described_class::Helpers).to be_a(Module)
  end

  it 'exposes the Runners namespace' do
    expect(described_class::Runners).to be_a(Module)
  end
end
