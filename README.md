# Ruby::Wfc

A Ruby implementation of the [Wave Function Collapse](https://github.com/mxgmn/WaveFunctionCollapse)
algorithm (overlapping model). It learns all N x N patterns of a small sample image and
generates new images of any size in which every N x N block also appears in the sample.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-wfc'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruby-wfc

## Usage

### Command line

    $ wfc                                   # built-in 5x5 sample -> result.png (50x50)
    $ wfc -i sample.png -o out.png -s 80x40 -n 3 --seed 42

| Option | Default | Meaning |
| --- | --- | --- |
| `-i`, `--input FILE` | built-in grayscale sample | sample PNG |
| `-o`, `--output FILE` | `result.png` | output PNG |
| `-s`, `--size WxH` | `50x50` | output size in pixels |
| `-n`, `--pattern-size N` | `2` | edge length of the learned patterns |
| `--[no-]rotations` | on | also learn rotated patterns |
| `--seed SEED` | random | reproducible output |
| `--attempts N` | `10` | attempts before giving up (an attempt ends at a contradiction) |

From a checkout use `bundle exec exe/wfc ...`.

### Ruby

```ruby
require "wfc"

sample = [
  [255, 255, 255, 255, 255],
  [255, 138, 138,   0,   0],
  [255, 138, 138,   0,   0],
  [255, 138, 138, 138,  38],
  [255,   0,   0, 255, 255]
]

model  = Wfc::OverlappingModel.new(sample, pattern_size: 2, rotations: true)
pixels = model.generate(width: 50, height: 50, seed: 1) # => pixels[y][x]
```

Pixels can be any values that support `==` and `hash` (integers, symbols, colors, ...).
If no contradiction-free result is found after `max_attempts` attempts, or the patterns
cannot fill an image of the requested size at all, `Wfc::GenerationFailedError` is raised.

PNG helpers (pixels are ChunkyPNG RGBA colors unless you map them with a block):

```ruby
require "wfc/png"

sample = Wfc::PNG.load("sample.png")
pixels = Wfc::OverlappingModel.new(sample, pattern_size: 3).generate(width: 64, height: 64)
Wfc::PNG.save(pixels, "out.png")

# grayscale values -> colors
Wfc::PNG.save(grayscale_pixels, "out.png") { |v| ChunkyPNG::Color.grayscale(v) }
```

### How it works

1. `PatternExtractor` cuts every N x N block (plus rotations) out of the sample and counts them.
2. `AdjacencyRules` stores, for each pattern and each of the 4 directions, which patterns
   overlap it consistently.
3. `Wave` starts with every pattern possible in every cell, then repeatedly collapses the cell
   with the lowest Shannon entropy to one pattern (weighted by frequency) and propagates the
   consequences by counting supporters per pattern and direction.
4. Each output pixel is the top-left pixel of the pattern chosen for its cell. Only cells whose
   pattern fits into the image are part of the wave, so the last N - 1 columns and rows are
   taken from the rest of the patterns of the last cells.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/webmatze/ruby-wfc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/webmatze/ruby-wfc/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby::Wfc project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/webmatze/ruby-wfc/blob/main/CODE_OF_CONDUCT.md).
