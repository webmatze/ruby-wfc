# frozen_string_literal: true

module Wfc
  # Cuts every N x N block out of a sample image (non-wrapping) and counts how
  # often each distinct pattern occurs.
  class PatternExtractor
    # @param sample [Array<Array>] rectangular image, `sample[y][x]`
    # @param size [Integer] edge length N of the extracted patterns
    # @param rotations [Boolean] also count the 90/180/270 degree rotations
    def initialize(sample, size:, rotations: true)
      validate!(sample, size)

      @sample = sample
      @size = size
      @rotations = rotations
    end

    # @return [Hash{Pattern => Integer}] pattern => number of occurrences, in order of first appearance
    def call
      each_block.with_object(Hash.new(0)) do |pattern, weights|
        variants = @rotations ? pattern.rotations : [pattern]
        variants.each { |variant| weights[variant] += 1 }
      end
    end

    private

    def each_block
      return enum_for(:each_block) unless block_given?

      height = @sample.length
      width = @sample.first.length

      (0..height - @size).each do |y|
        (0..width - @size).each do |x|
          yield Pattern.new(@sample[y, @size].map { |row| row[x, @size] })
        end
      end
    end

    def validate!(sample, size)
      raise ArgumentError, "pattern size must be a positive Integer" unless size.is_a?(Integer) && size.positive?

      validate_sample!(sample)
      return if [sample.length, sample.first.length].min >= size

      raise ArgumentError, "sample must be at least #{size}x#{size} pixels"
    end

    def validate_sample!(sample)
      unless sample.is_a?(Array) && !sample.empty? && sample.all?(Array) && !sample.first.empty?
        raise ArgumentError, "sample must be a non-empty 2D array"
      end
      raise ArgumentError, "sample rows must all have the same length" unless sample.map(&:length).uniq.one?
    end
  end
end
