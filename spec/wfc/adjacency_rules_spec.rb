# frozen_string_literal: true

RSpec.describe Wfc::AdjacencyRules do
  let(:patterns) do
    [
      Wfc::Pattern.new([[0, 0], [0, 0]]),
      Wfc::Pattern.new([[0, 1], [0, 1]]),
      Wfc::Pattern.new([[1, 1], [1, 1]])
    ]
  end
  let(:rules) { described_class.new(patterns) }
  let(:right) { described_class::DIRECTIONS.index([1, 0]) }
  let(:left) { described_class::DIRECTIONS.index([-1, 0]) }

  it "constrains the four direct neighbours" do
    expect(described_class::DIRECTIONS).to contain_exactly([1, 0], [-1, 0], [0, 1], [0, -1])
    described_class::DIRECTIONS.each_with_index do |(dx, dy), direction|
      expect(described_class::DIRECTIONS[described_class.opposite(direction)]).to eq([-dx, -dy])
    end
  end

  it "lists the patterns allowed next to a pattern" do
    # right of all-zero: blocks whose left column is zero
    expect(rules.neighbours(0, right)).to eq([0, 1])
    # right of [0 1]: blocks whose left column is one
    expect(rules.neighbours(1, right)).to eq([2])
    expect(rules.neighbours(2, left)).to eq([1, 2])
  end

  it "is symmetric: a allows b on one side iff b allows a on the other" do
    patterns.each_index do |a|
      described_class::DIRECTIONS.each_index do |direction|
        rules.neighbours(a, direction).each do |b|
          expect(rules.neighbours(b, described_class.opposite(direction))).to include(a)
        end
      end
    end
  end
end
