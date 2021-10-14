# frozen_string_literal: true

require_relative "wfc/version"

pixels = [
  [255, 255, 255, 255],
  [255, 0, 0, 0],
  [255, 0, 138, 0],
  [255, 0, 0, 0]
]
input_size = [4, 4]
OUTPUT_SIZE = [50, 50].freeze

p(pixels)

class Pattern
  attr_accessor :pixels

  def initialize(pixels)
    @pixels = pixels
  end

  def length
    1
  end
end

# WIP: Return original array as well as rotated by 90, 180 and 270 degrees in the form of tuples
def get_all_rotations(pattern)
  [pattern]
end

N = 2 # pattern size
patterns = []
weights = {} # dict pattern -> occurence
probability = {} # dict pattern -> probability
(0..input_size[0] - (N - 1) - 1).each do |y| # row
  (0..input_size[1] - (N - 1) - 1).each do |x| # column
    puts "#{x}:#{y}"
    pattern = []
    pixels[y...y + N].each do |k|
      puts "k=#{k}"
      pattern.push(k[x...x + N].map(&:to_i)) # change array to int really quick
    end
    puts "pattern=#{pattern}"
    pattern_rotations = get_all_rotations(pattern)

    pattern_rotations.each do |rotation|
      if !weights.include? rotation
        weights[rotation] = 1
      else
        weights[rotation] += 1
      end
    end

    patterns.concat(pattern_rotations)
  end
end
puts "weights=#{weights}"

# remove duplicates
patterns_without_duplicates = []
patterns.each do |pattern|
  patterns_without_duplicates.push(pattern) unless patterns_without_duplicates.include? pattern
end
patterns = patterns_without_duplicates

puts "final_patterns=#{patterns}"

sum_of_weights = 0
weights.each_value do |weight|
  sum_of_weights += weight
end

patterns.each do |pattern|
  probability[pattern] = weights[pattern] / sum_of_weights
end

# convert patterns from tuples into Pattern objects
patterns = patterns.map { |pattern| Pattern.new(pattern) }
pattern_weights = {}
pattern_probability = {}
patterns.each do |pattern|
  pattern_weights[pattern] = weights[pattern.pixels]
  pattern_probability[pattern] = probability[pattern.pixels]
end

puts "pattern_weights=#{pattern_weights}"
puts "pattern_probability=#{pattern_probability}"

UP = [0, -1].freeze
LEFT = [-1, 0].freeze
DOWN = [0, 1].freeze
RIGHT = [1, 0].freeze
UP_LEFT = [-1, -1].freeze
UP_RIGHT = [1, -1].freeze
DOWN_LEFT = [-1, 1].freeze
DOWN_RIGHT = [1, 1].freeze
DIRS = [UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT].freeze

puts "dirs=#{DIRS}"

def valid_dirs(pos)
  x, y = pos

  valid_directions = []

  case x
  when 0
    valid_directions.concat([RIGHT])
    case y
    when 0
      valid_directions.concat([DOWN, DOWN_RIGHT])
    when OUTPUT_SIZE[1] - 1
      valid_directions.concat([UP, UP_RIGHT])
    else
      valid_directions.concat([DOWN, DOWN_RIGHT, UP, UP_RIGHT])
    end
  when OUTPUT_SIZE[0] - 1
    valid_directions.concat([LEFT])
    case y
    when 0
      valid_directions.concat([DOWN, DOWN_LEFT])
    when OUTPUT_SIZE[1] - 1
      valid_directions.concat([UP, UP_LEFT])
    else
      valid_directions.concat([DOWN, DOWN_LEFT, UP, UP_LEFT])
    end
  else
    valid_directions.concat([LEFT, RIGHT])
    case y
    when 0
      valid_directions.concat([DOWN, DOWN_LEFT, DOWN_RIGHT])
    when OUTPUT_SIZE[1] - 1
      valid_directions.concat([UP, UP_LEFT, UP_RIGHT])
    else
      valid_directions.concat([UP, UP_LEFT, UP_RIGHT, DOWN, DOWN_LEFT, DOWN_RIGHT])
    end
  end

  valid_directions
end

# Tells which combinations of patterns are allowed for all patterns
#
#     data (dict):
#         pattern -> posible_connections (dict):
#                     relative_position -> patterns (list)
class Index
  attr_accessor :data

  def initialize(patterns: [])
    @data = {}
    patterns.each do |pattern|
      @data[pattern] = {}
      DIRS.each do |d|
        @data[pattern][d] = []
      end
    end
  end

  def add_rule(pattern: Pattern, relative_position: tuple, next_pattern: Pattern)
    @data[pattern][relative_position].push(next_pattern)
  end

  def check_possibility(pattern: Pattern, check_pattern: Pattern, relative_pos: tuple)
    pattern = pattern[0] if pattern.is_a? Array

    @data[pattern][relative_pos].include? check_pattern
  end

  def to_s
    data.to_s
  end
end

$index = Index.new(patterns: patterns)
puts "index=#{$index}"

def get_offset_tiles(pattern:, offset:)
  return pattern.pixels if offset == [0, 0]
  return [pattern.pixels[1][1]] if offset == [-1, -1]
  return pattern.pixels[1][0...] if offset == [0, -1]
  return [pattern.pixels[1][0]] if offset == [1, -1]
  return [pattern.pixels[0][1], pattern.pixels[1][1]] if offset == [-1, 0]
  return [pattern.pixels[0][0], pattern.pixels[1][0]] if offset == [1, 0]
  return [pattern.pixels[0][1]] if offset == [-1, 1]
  return pattern.pixels[0][0...] if offset == [0, 1]
  return [pattern.pixels[0][0]] if offset == [1, 1]
end

# Generate rules for Index and save them
rules_num = 0
patterns.each do |pattern|
  DIRS.each do |d|
    patterns.each do |pattern_next|
      # here's checking all offsets
      overlap = get_offset_tiles(pattern: pattern_next, offset: d)
      og_dir = [d[0] * -1, d[1] * -1]
      part_of_og_pattern = get_offset_tiles(pattern: pattern, offset: og_dir)
      if (overlap) == (part_of_og_pattern)
        $index.add_rule(pattern: pattern, relative_position: d, next_pattern: pattern_next)
        rules_num += 1
      end
    end
  end
end

puts "index=#{$index}"

# Initialize wave function of the size 'size' where in each tile no patterns are forbidden yet.
# Coefficients describe what patterns can occur in each tile. At the beginning, at every position there == full set
# of patterns available
def initialize_wave_function(size:, patterns:)
  coefficients = []

  (0..size[0] - 1).each do |_col|
    row = []
    (0..size[1] - 1).each do |_r|
      row.push(patterns)
    end
    coefficients.push(row)
  end
  coefficients
end

coefficients = initialize_wave_function(size: OUTPUT_SIZE, patterns: patterns)
puts "coefficients=#{coefficients}"

# Check if wave function == fully collapsed meaning that for each tile available is only one pattern
def is_fully_collapsed(coefficients)
  coefficients.each do |col|
    col.each do |entry|
      return false if entry.length > 1
    end
  end
  true
end

# Return possible patterns at position (x, y)
def get_possible_patterns_at_position(position, coefficients)
  x, y = position
  possible_patterns = coefficients[x][y]
end

# Calculate the Shannon Entropy of the wavefunction at position (x, y)
def get_shannon_entropy(position, coefficients, probability)
  x, y = position
  entropy = 0

  # A cell with one valid pattern has 0 entropy
  return 0 if coefficients[x][y].length == 1

  coefficients[x][y].each do |pattern|
    entropy += probability[pattern.pixels] * Math.log(probability[pattern.pixels], 2)
  end
  entropy *= -1

  # Add noise to break ties and near-ties
  entropy -= rand(0..0.1)
  entropy
end

# Return position of tile with the lowest entropy
def get_min_entropy_pos(coefficients, probability)
  min_entropy = nil
  min_entropy_pos = nil

  coefficients.each_with_index do |col, x|
    col.each_with_index do |_row, y|
      entropy = get_shannon_entropy([x, y], coefficients, probability)

      next if entropy.zero?

      if min_entropy.nil? || entropy < min_entropy
        min_entropy = entropy
        min_entropy_pos = [x, y]
      end
    end
  end
  min_entropy_pos
end

def observe(coefficients, probability)
  # Find the lowest entropy
  min_entropy_pos = get_min_entropy_pos(coefficients, probability)

  if min_entropy_pos.nil?
    puts("All tiles have 0 entropy")
    return
  end

  # Choose a pattern at lowest entropy position which is most frequent in the sample
  possible_patterns = get_possible_patterns_at_position(min_entropy_pos, coefficients)

  # calculate max probability for patterns that are left
  max_p = 0
  possible_patterns.each do |pattern|
    max_p = probability[pattern.pixels] if max_p < probability[pattern.pixels]
  end


  semi_random_pattern = possible_patterns.select { |pat| probability[pat.pixels] >= max_p }.sample

  # Set this pattern to be the only available at this position
  coefficients[min_entropy_pos[0]][min_entropy_pos[1]] = semi_random_pattern

  min_entropy_pos
end

def propagate(min_entropy_pos, coefficients)
  stack = [min_entropy_pos]

  while stack.length.positive?
    pos = stack.pop

    possible_patterns = get_possible_patterns_at_position(pos, coefficients)

    # Iterate through each location immediately adjacent to the current location
    valid_dirs(pos).each do |d|
      adjacent_pos = [pos[0] + d[0], pos[1] + d[1]]
      possible_patterns_at_adjacent = get_possible_patterns_at_position(adjacent_pos, coefficients)

      # Iterate over all still available patterns in adjacent tile
      # and check if pattern is still possible in this location
      possible_patterns_at_adjacent = [possible_patterns_at_adjacent] unless possible_patterns_at_adjacent.is_a? Array
      possible_patterns_at_adjacent.each do |possible_pattern_at_adjacent|
        is_possible = if possible_patterns.length > 1
                        possible_patterns.any? do |pattern|
                          $index.check_possibility(pattern: pattern, check_pattern: possible_pattern_at_adjacent, relative_pos: d)
                        end
                      else
                        $index.check_possibility(pattern: possible_patterns, check_pattern: possible_pattern_at_adjacent, relative_pos: d)
                      end

        # If the tile is !compatible with any of the tiles in the current location's wave function
        # then it's impossible for it to ever get chosen so it needs to be removed from the other
        # location's wave function
        unless is_possible
          x, y = adjacent_pos
          coefficients[x][y] = coefficients[x][y].reject { |patt| patt.pixels == possible_pattern_at_adjacent.pixels } 

          stack.push(adjacent_pos) unless stack.include? adjacent_pos
        end
      end
    end
  end
end


until is_fully_collapsed(coefficients)
  min_entropy_pos = observe(coefficients, probability)
  propagate(min_entropy_pos, coefficients)
end

final_pixels = []

coefficients.each do |i|
  row = []
  i.each do |j|
    first_pixel = if j.is_a? Array
                    j[0].pixels[0][0]
                  else
                    j.pixels[0][0]
                  end
    row.push(first_pixel)
  end
  final_pixels.push(row)
end



puts final_pixels