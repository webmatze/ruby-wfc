# frozen_string_literal: true

RSpec.describe Wfc::Wave do
  def wave_for(sample, width:, height:, seed: 1)
    model = Wfc::OverlappingModel.new(sample, pattern_size: 2, rotations: false)
    rules = Wfc::AdjacencyRules.new(model.patterns)
    described_class.new(width: width, height: height, weights: model.weights, rules: rules, rng: Random.new(seed))
  end

  it "collapses every cell to exactly one pattern" do
    wave = wave_for([[0, 1, 0], [1, 0, 1], [0, 1, 0]], width: 5, height: 4).collapse!
    indices = wave.pattern_indices
    expect(indices.length).to eq(4)
    expect(indices.flatten).to all(be_between(0, 1))
  end

  it "refuses to report patterns before collapsing" do
    wave = wave_for([[0, 1, 0], [1, 0, 1], [0, 1, 0]], width: 3, height: 3)
    expect { wave.pattern_indices }.to raise_error(Wfc::Error, /not fully collapsed/)
  end

  it "raises a ContradictionError when no pattern fits" do
    # [0 1] never fits next to itself horizontally, so a 3x1 output is impossible.
    patterns = [Wfc::Pattern.new([[0, 1], [0, 1]])]
    rules = Wfc::AdjacencyRules.new(patterns)
    wave = described_class.new(width: 3, height: 1, weights: [1], rules: rules, rng: Random.new(1))
    expect { wave.collapse! }.to raise_error(Wfc::ContradictionError)
  end

  it "validates its size" do
    expect { wave_for([[0, 1], [1, 0]], width: 0, height: 3) }.to raise_error(ArgumentError)
  end
end
