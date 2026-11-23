# frozen_string_literal: true

RSpec.describe Wfc::Pattern do
  subject(:pattern) { described_class.new([[1, 2], [3, 4]]) }

  it "is immutable" do
    expect(pattern).to be_frozen
    expect(pattern.pixels).to be_frozen
    expect(pattern.pixels.first).to be_frozen
  end

  it "rejects non-square input" do
    expect { described_class.new([[1, 2], [3]]) }.to raise_error(ArgumentError)
    expect { described_class.new([]) }.to raise_error(ArgumentError)
  end

  it "accesses pixels by x/y" do
    expect(pattern[1, 0]).to eq(2)
    expect(pattern[0, 1]).to eq(3)
    expect(pattern.top_left).to eq(1)
  end

  it "behaves as a value object" do
    other = described_class.new([[1, 2], [3, 4]])
    expect(pattern).to eq(other)
    expect(pattern).to eql(other)
    expect({ pattern => :x }[other]).to eq(:x)
    expect(pattern).not_to eq(described_class.new([[1, 2], [3, 5]]))
  end

  it "rotates clockwise" do
    expect(pattern.rotate.pixels).to eq([[3, 1], [4, 2]])
    expect(pattern.rotations.map(&:pixels)).to eq([
                                                    [[1, 2], [3, 4]],
                                                    [[3, 1], [4, 2]],
                                                    [[4, 3], [2, 1]],
                                                    [[2, 4], [1, 3]]
                                                  ])
  end

  describe "#overlaps?" do
    it "compares the overlapping column for horizontal neighbours" do
      right = described_class.new([[2, 9], [4, 9]])
      expect(pattern.overlaps?(right, 1, 0)).to be(true)
      expect(pattern.overlaps?(right, -1, 0)).to be(false)
    end

    it "compares the overlapping row for vertical neighbours" do
      above = described_class.new([[9, 9], [1, 2]])
      expect(pattern.overlaps?(above, 0, -1)).to be(true)
      expect(pattern.overlaps?(above, 0, 1)).to be(false)
    end

    it "compares a single pixel for diagonal neighbours" do
      down_right = described_class.new([[4, 0], [0, 0]])
      expect(pattern.overlaps?(down_right, 1, 1)).to be(true)
      expect(down_right.overlaps?(pattern, -1, -1)).to be(true)
    end

    it "works for larger patterns" do
      big = described_class.new([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
      shifted = described_class.new([[5, 6, 0], [8, 9, 0], [0, 0, 0]])
      expect(big.overlaps?(shifted, 1, 1)).to be(true)
      expect(big.overlaps?(shifted, 1, 0)).to be(false)
    end

    it "is true for patterns that are too far apart to share a pixel" do
      other = described_class.new([[9, 9], [9, 9]])
      [[2, 0], [3, 0], [-3, 0], [-4, 0], [0, 3], [0, -4], [5, 5]].each do |dx, dy|
        expect(pattern.overlaps?(other, dx, dy)).to be(true)
      end
      expect(pattern.overlap(-3, 0)).to eq([[], []])
    end
  end
end
