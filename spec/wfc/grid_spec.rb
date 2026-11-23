# frozen_string_literal: true

RSpec.describe Wfc::Grid do
  subject(:grid) { described_class.new(3, 2) }

  let(:directions) { Wfc::AdjacencyRules::DIRECTIONS }

  it "numbers cells row by row" do
    expect(grid.size).to eq(6)
    expect(grid.position(4)).to eq([1, 1])
  end

  it "finds neighbours inside the grid only" do
    expect(grid.neighbour(0, directions.index([1, 0]))).to eq(1)
    expect(grid.neighbour(0, directions.index([0, 1]))).to eq(3)
    expect(grid.neighbour(0, directions.index([-1, 0]))).to be_nil
    expect(grid.neighbour(5, directions.index([1, 0]))).to be_nil
    expect(grid.neighbour(5, directions.index([0, -1]))).to eq(2)
  end

  it "rejects empty grids" do
    expect { described_class.new(0, 2) }.to raise_error(ArgumentError)
  end
end
