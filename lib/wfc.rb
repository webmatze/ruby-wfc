# frozen_string_literal: true

require_relative "wfc/version"
require_relative "wfc/errors"
require_relative "wfc/bitmask"
require_relative "wfc/pattern"
require_relative "wfc/pattern_extractor"
require_relative "wfc/adjacency_rules"
require_relative "wfc/grid"
require_relative "wfc/wave"
require_relative "wfc/overlapping_model"

# Ruby implementation of the (overlapping) Wave Function Collapse algorithm.
#
#   sample = [
#     [255, 255, 255],
#     [255,   0, 255],
#     [255, 255, 255]
#   ]
#   model  = Wfc::OverlappingModel.new(sample, pattern_size: 2)
#   output = model.generate(width: 20, height: 20, seed: 42) # => 2D array, output[y][x]
#
# PNG reading/writing lives in "wfc/png" (requires the chunky_png gem).
module Wfc
end
