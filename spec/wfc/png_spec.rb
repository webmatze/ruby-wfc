# frozen_string_literal: true

require "tmpdir"
require "wfc/png"

RSpec.describe Wfc::PNG do
  it "round-trips pixels through a PNG file" do
    red = ChunkyPNG::Color.rgb(255, 0, 0)
    blue = ChunkyPNG::Color.rgb(0, 0, 255)
    pixels = [[red, blue, red], [blue, red, blue]]

    Dir.mktmpdir do |dir|
      path = File.join(dir, "test.png")
      described_class.save(pixels, path)
      expect(described_class.load(path)).to eq(pixels)
    end
  end

  it "maps values to colors with a block" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "gray.png")
      described_class.save([[0, 255]], path) { |v| ChunkyPNG::Color.grayscale(v) }
      expect(described_class.load(path)).to eq([[ChunkyPNG::Color.grayscale(0), ChunkyPNG::Color.grayscale(255)]])
    end
  end
end
