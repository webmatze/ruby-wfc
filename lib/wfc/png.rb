# frozen_string_literal: true

require "chunky_png"

module Wfc
  # Converts between PNG files and the 2D pixel arrays used by Wfc.
  #
  # Pixels are ChunkyPNG color integers (RGBA) unless a block is given.
  module PNG
    module_function

    # @return [Array<Array<Integer>>] `pixels[y][x]` as ChunkyPNG colors
    def load(path)
      image = ChunkyPNG::Image.from_file(path)
      Array.new(image.height) { |y| image.row(y) }
    end

    # Writes `pixels[y][x]` to `path`.
    #
    # @yieldparam value pixel value; the block must return a ChunkyPNG color.
    #   Without a block the values are expected to be ChunkyPNG colors already.
    #
    # @example grayscale values (0-255)
    #   Wfc::PNG.save(pixels, "out.png") { |v| ChunkyPNG::Color.grayscale(v) }
    def save(pixels, path, &to_color)
      to_color ||= ->(value) { value }
      image = ChunkyPNG::Image.new(pixels.first.length, pixels.length, ChunkyPNG::Color::TRANSPARENT)

      pixels.each_with_index do |row, y|
        row.each_with_index { |value, x| image[x, y] = to_color.call(value) }
      end
      image.save(path)
    end
  end
end
