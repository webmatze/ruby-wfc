# frozen_string_literal: true

module Wfc
  # The state of the output grid while it is being generated.
  #
  # Every cell holds a bitmask of the patterns that are still possible there.
  # `collapse!` repeatedly picks the cell with the lowest Shannon entropy, fixes
  # it to one pattern (weighted by how often the pattern occurs in the sample)
  # and propagates the consequences to the surrounding cells.
  #
  # Propagation counts supporters (as in Gumin's reference implementation):
  # for every cell, pattern and direction we track how many patterns of the
  # neighbour on that side still allow the pattern. When the count drops to
  # zero the pattern is banned, which may in turn ban patterns further away.
  class Wave
    # Tiny random noise used to break ties between cells with equal entropy.
    NOISE = 1e-6
    DIRECTIONS = AdjacencyRules::DIRECTIONS

    attr_reader :grid

    # @param weights [Array<Integer>] occurrence count per pattern index
    # @param rules [AdjacencyRules]
    # @param rng [Random]
    def initialize(width:, height:, weights:, rules:, rng:)
      @grid = Grid.new(width, height)
      @weights = weights
      @log_weights = weights.map { |w| w * Math.log(w) }
      @rules = rules
      @rng = rng
      @banned = [] # flat queue of [cell, pattern] pairs waiting to be propagated
      reset_cells
      reset_support
    end

    # Runs observe/propagate until every cell holds exactly one pattern.
    # @raise [ContradictionError] if a cell runs out of possible patterns
    # @return [self]
    def collapse!
      ban_unsupported
      propagate
      while (cell = lowest_entropy_cell)
        observe(cell)
        propagate
      end
      self
    end

    # @return [Array<Array<Integer>>] the chosen pattern index per cell, `result[y][x]`
    def pattern_indices
      raise Error, "wave is not fully collapsed yet" unless @cells.all? { |mask| Bitmask.single?(mask) }

      @cells.map { |mask| Bitmask.last_index(mask) }.each_slice(grid.width).to_a
    end

    private

    # Every cell starts with all patterns possible. The weight sums are cached
    # per cell so the entropy does not have to be recomputed from scratch.
    def reset_cells
      @cells = Array.new(grid.size, (1 << @weights.length) - 1)
      @weight_sum = Array.new(grid.size, @weights.sum.to_f)
      @log_weight_sum = Array.new(grid.size, @log_weights.sum)
    end

    # `@support[slot(cell, pattern, direction)]` = number of patterns in the cell
    # *opposite* to `direction` that allow `pattern` at `cell`. Pattern `a`
    # allows `b` on one side exactly when `b` allows `a` on the other side, so
    # the initial value is the number of neighbours `pattern` has on that side.
    def reset_support
      initial = Array.new(@weights.length) do |pattern|
        Array.new(DIRECTIONS.size) do |direction|
          @rules.neighbours(pattern, AdjacencyRules.opposite(direction)).size
        end
      end.flatten
      @support = initial * grid.size
    end

    def slot(cell, pattern, direction)
      (((cell * @weights.length) + pattern) * DIRECTIONS.size) + direction
    end

    # Bans patterns that can never be supported, e.g. a pattern that has no
    # possible right neighbour cannot appear anywhere except in the last column.
    def ban_unsupported
      @cells.each_index do |cell|
        DIRECTIONS.each_index do |direction|
          next unless grid.neighbour(cell, AdjacencyRules.opposite(direction))

          @weights.each_index { |pattern| ban(cell, pattern) if @support[slot(cell, pattern, direction)].zero? }
        end
      end
    end

    # Shannon entropy of the weighted pattern distribution of a cell:
    #   H = log(sum(w)) - sum(w * log(w)) / sum(w)
    def entropy(cell)
      sum = @weight_sum[cell]
      Math.log(sum) - (@log_weight_sum[cell] / sum)
    end

    # @return [Integer, nil] index of the undecided cell with the lowest entropy
    def lowest_entropy_cell
      best = nil
      best_entropy = nil

      @cells.each_with_index do |mask, cell|
        next if Bitmask.single?(mask)

        value = entropy(cell) + (@rng.rand * NOISE)
        if best_entropy.nil? || value < best_entropy
          best = cell
          best_entropy = value
        end
      end
      best
    end

    # Fixes the cell to one of its remaining patterns, chosen weighted by frequency.
    def observe(cell)
      candidates = Bitmask.indices(@cells[cell])
      target = @rng.rand * candidates.sum { |index| @weights[index] }

      chosen = candidates.find do |index|
        target -= @weights[index]
        target.negative?
      end || candidates.last
      candidates.each { |pattern| ban(cell, pattern) unless pattern == chosen }
    end

    # Removes the support of every banned pattern from its neighbours.
    def propagate
      until @banned.empty?
        pattern = @banned.pop
        cell = @banned.pop

        DIRECTIONS.each_index do |direction|
          neighbour = grid.neighbour(cell, direction)
          @rules.neighbours(pattern, direction).each { |other| weaken(neighbour, other, direction) } if neighbour
        end
      end
    end

    # One supporter of `pattern` in `cell` (from the side opposite `direction`) is gone.
    def weaken(cell, pattern, direction)
      index = slot(cell, pattern, direction)
      @support[index] -= 1
      ban(cell, pattern) if @support[index].zero?
    end

    # Removes `pattern` from `cell` and queues it for propagation.
    def ban(cell, pattern)
      bit = 1 << pattern
      mask = @cells[cell]
      return if (mask & bit).zero?
      raise ContradictionError, grid.position(cell) if mask == bit

      @cells[cell] = mask ^ bit
      @weight_sum[cell] -= @weights[pattern]
      @log_weight_sum[cell] -= @log_weights[pattern]
      @banned.push(cell, pattern)
    end
  end
end
