# frozen_string_literal: true

RSpec.describe Wfc::OverlappingModel do
  let(:sample) do
    [
      [255, 255, 255, 255, 255],
      [255, 138, 138, 0, 0],
      [255, 138, 138, 0, 0],
      [255, 138, 138, 138, 38],
      [255, 0, 0, 255, 255]
    ]
  end
  let(:model) { described_class.new(sample, pattern_size: 2) }

  def blocks(image, size)
    (0..image.length - size).flat_map do |y|
      (0..image.first.length - size).map { |x| image[y, size].map { |row| row[x, size] } }
    end
  end

  it "learns patterns and their weights" do
    expect(model.patterns.size).to eq(42)
    expect(model.weights.sum).to eq(16 * 4)
  end

  it "computes probabilities that sum up to one" do
    expect(model.probabilities.values.sum).to be_within(1e-9).of(1.0)
    expect(model.probabilities.values).to all(be > 0)
  end

  it "generates an image of the requested (non-square) size" do
    result = model.generate(width: 8, height: 6, seed: 1)
    expect(result.length).to eq(6)
    expect(result).to all(have_attributes(length: 8))
  end

  it "only produces blocks that are known patterns" do
    known = model.patterns.map(&:pixels)
    [[12, 9], [9, 12], [20, 20]].each_with_index do |(width, height), seed|
      result = model.generate(width: width, height: height, seed: seed)
      expect(blocks(result, 2) - known).to be_empty
    end
  end

  it "is reproducible with a seed" do
    expect(model.generate(width: 10, height: 10, seed: 7)).to eq(model.generate(width: 10, height: 10, seed: 7))
  end

  it "supports bigger patterns" do
    stripes = Array.new(6) { |y| Array.new(6) { |x| (x + y).even? ? :a : :b } }
    big = described_class.new(stripes, pattern_size: 3, rotations: false)
    result = big.generate(width: 7, height: 5, seed: 3)
    expect(blocks(result, 3) - big.patterns.map(&:pixels)).to be_empty
  end

  it "rejects a non-positive number of attempts" do
    expect { model.generate(width: 4, height: 4, max_attempts: 0) }.to raise_error(ArgumentError)
  end

  it "retries after contradictions and gives up eventually" do
    calls = 0
    allow_any_instance_of(Wfc::Wave).to receive(:collapse!) do
      calls += 1
      raise Wfc::ContradictionError, [0, 0]
    end

    expect { model.generate(width: 4, height: 4, seed: 1, max_attempts: 3) }
      .to raise_error(Wfc::GenerationFailedError)
    expect(calls).to eq(3)
  end
end
