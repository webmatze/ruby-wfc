# frozen_string_literal: true

module Wfc
  class Error < StandardError; end

  # Raised when a cell of the wave ends up with no possible pattern left.
  class ContradictionError < Error
    attr_reader :position

    def initialize(position)
      @position = position
      super("Contradiction at #{position.inspect}: no pattern fits this cell")
    end
  end

  # A contradiction found before anything random was decided: the patterns
  # cannot fill a grid of this size at all, so trying again cannot help.
  class UnsatisfiableError < ContradictionError; end

  # Raised when no attempt out of `max_attempts` finished without a contradiction,
  # or when the patterns cannot fill the requested size at all.
  class GenerationFailedError < Error; end
end
