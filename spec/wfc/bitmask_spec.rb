# frozen_string_literal: true

RSpec.describe Wfc::Bitmask do
  it "lists set bits" do
    expect(described_class.indices(0b10110)).to eq([1, 2, 4])
    expect(described_class.indices(0)).to eq([])
    expect(described_class.indices((1 << 300) | 1)).to eq([0, 300])
  end

  it "detects single bits" do
    expect(described_class.single?(0b1000)).to be(true)
    expect(described_class.single?(0b1010)).to be(false)
    expect(described_class.single?(0)).to be(false)
    expect(described_class.last_index(0b1000)).to eq(3)
  end
end
