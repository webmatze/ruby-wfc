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

  # Raised when no attempt out of `max_attempts` finished without a contradiction.
  class GenerationFailedError < Error; end
end
