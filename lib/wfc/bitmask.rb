# frozen_string_literal: true

module Wfc
  # Helpers for sets of pattern indices stored as Integer bitmasks
  # (bit `i` set = pattern `i` is in the set).
  module Bitmask
    module_function

    # Yields the index of every set bit, highest first.
    #
    # Goes through the binary string once: shifting a large Integer bit by bit
    # would copy it on every step and make this quadratic.
    def each_index(mask)
      return enum_for(:each_index, mask) unless block_given?

      index = mask.bit_length
      mask.to_s(2).each_char do |bit|
        index -= 1
        yield index if bit == "1"
      end
    end

    # @return [Array<Integer>] indices of all set bits, ascending
    def indices(mask)
      each_index(mask).to_a.reverse
    end

    # Whether exactly one bit is set.
    def single?(mask)
      mask.positive? && (mask & (mask - 1)).zero?
    end

    # Index of the highest set bit (the only one, if `single?`).
    def last_index(mask)
      mask.bit_length - 1
    end
  end
end
