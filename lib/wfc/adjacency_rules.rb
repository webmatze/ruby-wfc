# frozen_string_literal: true

module Wfc
  # Precomputes which patterns may sit next to each other.
  #
  # Each output cell holds a pattern whose top-left pixel is drawn at that cell,
  # so horizontally/vertically adjacent cells overlap by N - 1 columns/rows.
  # Checking only those 4 directions is enough: if all adjacent cells agree on
  # their overlap, every N x N window of the output equals the pattern of its
  # top-left cell. (Cells further away are still constrained, transitively.)
  class AdjacencyRules
    # [dx, dy] per direction: right, left, down, up. Opposite directions differ
    # only in the lowest bit, so `direction ^ 1` is the opposite direction.
    DIRECTIONS = [[1, 0], [-1, 0], [0, 1], [0, -1]].map(&:freeze).freeze

    def self.opposite(direction)
      direction ^ 1
    end

    # @param patterns [Array<Pattern>]
    def initialize(patterns)
      @neighbours = build_table(patterns)
    end

    # @return [Array<Integer>] indices of the patterns that may be placed in
    #   `direction` (an index into DIRECTIONS) of the pattern with index `index`
    def neighbours(index, direction)
      @neighbours[index][direction]
    end

    private

    # For every direction, patterns are grouped by the pixels they would share
    # with a neighbour; a pattern is compatible with exactly the group matching
    # its own overlap. That is linear in the number of patterns instead of quadratic.
    def build_table(patterns)
      table = Array.new(patterns.size) { [] }
      DIRECTIONS.each_with_index do |(dx, dy), direction|
        groups = group_by_overlap(patterns, -dx, -dy)
        patterns.each_with_index do |pattern, index|
          table[index][direction] = groups.fetch(pattern.overlap(dx, dy), []).freeze
        end
      end
      table
    end

    # @return [Hash{Array => Array<Integer>}] overlap pixels => pattern indices
    def group_by_overlap(patterns, dx, dy)
      groups = Hash.new { |hash, key| hash[key] = [] }
      patterns.each_with_index { |pattern, index| groups[pattern.overlap(dx, dy)] << index }
      groups
    end
  end
end
