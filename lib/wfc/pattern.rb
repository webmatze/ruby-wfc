# frozen_string_literal: true

module Wfc
  # An immutable square block of N x N pixels cut out of the sample image.
  #
  # Pixels are stored row-major: `pixels[y][x]`. Pixel values can be any objects
  # that implement `==`/`hash` (integers, color values, symbols, ...).
  # Two patterns with the same pixels are equal and can be used as hash keys.
  class Pattern
    attr_reader :pixels

    def initialize(pixels)
      unless !pixels.empty? && pixels.all? { |row| row.length == pixels.length }
        raise ArgumentError, "pattern must be a non-empty square, got #{pixels.inspect}"
      end

      @pixels = pixels.map { |row| row.dup.freeze }.freeze
      freeze
    end

    def size
      pixels.length
    end

    def [](x, y)
      pixels[y][x]
    end

    # The pixel that represents this pattern in the generated output.
    def top_left
      pixels[0][0]
    end

    # Rotated by 90 degrees clockwise.
    def rotate
      Pattern.new(pixels.transpose.map(&:reverse))
    end

    # The pattern itself followed by its 90, 180 and 270 degree rotations.
    def rotations
      [self].tap { |all| 3.times { all << all.last.rotate } }
    end

    # Whether `other`, placed `dx`/`dy` pixels away from this pattern, agrees with
    # it on every pixel where both patterns overlap.
    def overlaps?(other, dx, dy)
      overlap(dx, dy) == other.overlap(-dx, -dy)
    end

    # The pixels this pattern shares with a neighbour placed `dx`/`dy` pixels away,
    # row by row (in this pattern's coordinates). Empty if the neighbour is too
    # far away to share any pixel.
    def overlap(dx, dy)
      columns = shared(dx)
      shared(dy).map { |y| pixels[y][columns] }
    end

    def ==(other)
      other.is_a?(Pattern) && pixels == other.pixels
    end
    alias eql? ==

    def hash
      [Pattern, pixels].hash
    end

    def to_s
      "#<Wfc::Pattern #{pixels.inspect}>"
    end
    alias inspect to_s

    private

    # The indices along one axis that a neighbour `offset` pixels away covers too.
    # Without the clamp an offset beyond the pattern gives a range that Array#[]
    # reads as nil or as counting from the end of the row.
    def shared(offset)
      offset = offset.clamp(-size, size)
      [0, offset].max...[size, size + offset].min
    end
  end
end
