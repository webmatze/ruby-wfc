# frozen_string_literal: true

module Wfc
  # The overlapping Wave Function Collapse model.
  #
  # Learns N x N patterns and their neighbourhood rules from a sample image and
  # generates new, larger images in which every N x N block also occurs in the
  # sample (optionally rotated).
  class OverlappingModel
    attr_reader :patterns, :weights, :pattern_size

    # @param sample [Array<Array>] input image, `sample[y][x]`
    # @param pattern_size [Integer] edge length N of the patterns
    # @param rotations [Boolean] also learn rotated variants of every pattern
    def initialize(sample, pattern_size: 2, rotations: true)
      counts = PatternExtractor.new(sample, size: pattern_size, rotations: rotations).call

      @pattern_size = pattern_size
      @patterns = counts.keys.freeze
      @weights = counts.values.freeze
      @rules = AdjacencyRules.new(@patterns)
    end

    # Relative frequency of every pattern (sums up to 1.0).
    # @return [Hash{Pattern => Float}]
    def probabilities
      total = weights.sum.to_f
      patterns.zip(weights).to_h { |pattern, weight| [pattern, weight / total] }
    end

    # Generates a new image.
    #
    # Each attempt that runs into a contradiction is discarded and a new one is
    # started (with the same random generator, so results stay reproducible).
    #
    # A contradiction that occurs before the first random choice would repeat on
    # every attempt, so it fails right away instead of being retried.
    #
    # @param seed [Integer, nil] seed for reproducible results
    # @param max_attempts [Integer]
    # @return [Array<Array>] `width` x `height` pixels, `result[y][x]`
    # @raise [GenerationFailedError]
    def generate(width:, height:, seed: nil, max_attempts: 10)
      validate!(width, height, max_attempts)
      rng = seed.nil? ? Random.new : Random.new(seed)

      max_attempts.times do
        wave = Wave.new(width: cells(width), height: cells(height), weights: weights, rules: @rules, rng: rng)
        return render(wave.collapse!, width, height)
      rescue UnsatisfiableError => e
        raise GenerationFailedError, "the patterns cannot fill a #{width}x#{height} image (#{e.message})"
      rescue ContradictionError
        next
      end

      raise GenerationFailedError, "no contradiction-free result after #{max_attempts} attempts"
    end

    private

    def validate!(width, height, max_attempts)
      unless [width, height].all? { |length| length.is_a?(Integer) && length.positive? }
        raise ArgumentError, "width and height must be positive Integers"
      end
      return if max_attempts.is_a?(Integer) && max_attempts.positive?

      raise ArgumentError, "max_attempts must be a positive Integer"
    end

    # Number of wave cells along an edge of `length` pixels. Only cells whose
    # pattern fits into the image entirely are part of the wave: constraining
    # the cells beyond that would rule out images that are perfectly valid.
    def cells(length)
      [length - pattern_size + 1, 1].max
    end

    # The pattern of a cell covers the N x N pixels starting at that cell, so
    # the last N - 1 columns/rows are read from the patterns of the last cells.
    def render(wave, width, height)
      indices = wave.pattern_indices
      Array.new(height) do |y|
        Array.new(width) { |x| pixel(indices, x, y) }
      end
    end

    def pixel(indices, x, y)
      cell_y = [y, indices.length - 1].min
      cell_x = [x, indices.first.length - 1].min
      patterns[indices[cell_y][cell_x]][x - cell_x, y - cell_y]
    end
  end
end
