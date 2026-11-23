# frozen_string_literal: true

module Wfc
  # Geometry of the (non-wrapping) output grid. Cells are numbered row by row:
  # `cell = y * width + x`.
  class Grid
    attr_reader :width, :height

    def initialize(width, height)
      raise ArgumentError, "width and height must be positive" unless width.positive? && height.positive?

      @width = width
      @height = height
      directions = AdjacencyRules::DIRECTIONS.size
      @neighbours = Array.new(size * directions) { |i| compute_neighbour(*i.divmod(directions)) }.freeze
    end

    def size
      width * height
    end

    # @return [Array(Integer, Integer)] x and y of `cell`
    def position(cell)
      cell.divmod(width).reverse
    end

    # @param direction [Integer] index into AdjacencyRules::DIRECTIONS
    # @return [Integer, nil] the cell next to `cell` in `direction`, nil at the border
    def neighbour(cell, direction)
      @neighbours[(cell * AdjacencyRules::DIRECTIONS.size) + direction]
    end

    private

    def compute_neighbour(cell, direction)
      x, y = position(cell)
      dx, dy = AdjacencyRules::DIRECTIONS[direction]
      nx = x + dx
      ny = y + dy
      (ny * width) + nx if nx.between?(0, width - 1) && ny.between?(0, height - 1)
    end
  end
end
