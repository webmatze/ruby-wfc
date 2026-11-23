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
    # @param seed [Integer, nil] seed for reproducible results
    # @param max_attempts [Integer]
    # @return [Array<Array>] `width` x `height` pixels, `result[y][x]`
    # @raise [GenerationFailedError]
    def generate(width:, height:, seed: nil, max_attempts: 10)
      raise ArgumentError, "max_attempts must be positive" unless max_attempts.positive?

      rng = seed.nil? ? Random.new : Random.new(seed)

      max_attempts.times do
        wave = Wave.new(width: width, height: height, weights: weights, rules: @rules, rng: rng)
        return render(wave.collapse!)
      rescue ContradictionError
        next
      end

      raise GenerationFailedError, "no contradiction-free result after #{max_attempts} attempts"
    end

    private

    # Each output pixel is the top-left pixel of the pattern chosen for that cell.
    def render(wave)
      wave.pattern_indices.map do |row|
        row.map { |index| patterns[index].top_left }
      end
    end
  end
end
