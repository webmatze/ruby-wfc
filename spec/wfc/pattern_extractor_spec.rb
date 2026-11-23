# frozen_string_literal: true

RSpec.describe Wfc::PatternExtractor do
  let(:sample) do
    [
      [0, 0, 1],
      [0, 0, 1]
    ]
  end

  it "counts every block without rotations" do
    weights = described_class.new(sample, size: 2, rotations: false).call
    expect(weights).to eq(
      Wfc::Pattern.new([[0, 0], [0, 0]]) => 1,
      Wfc::Pattern.new([[0, 1], [0, 1]]) => 1
    )
  end

  it "adds all four rotations of every block" do
    weights = described_class.new(sample, size: 2).call
    expect(weights.values.sum).to eq(8)
    expect(weights[Wfc::Pattern.new([[0, 0], [0, 0]])]).to eq(4)
    expect(weights[Wfc::Pattern.new([[0, 0], [1, 1]])]).to eq(1)
  end

  it "validates its input" do
    expect { described_class.new(sample, size: 3).call }.to raise_error(ArgumentError, /at least 3x3/)
    expect { described_class.new([[1, 2], [3]], size: 1) }.to raise_error(ArgumentError, /same length/)
    expect { described_class.new([], size: 1) }.to raise_error(ArgumentError)
    expect { described_class.new(sample, size: 0) }.to raise_error(ArgumentError)
  end
end
