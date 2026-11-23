## [Unreleased]

### Changed

- Restructured the prototype script into a library: `Wfc::OverlappingModel`, `Pattern`,
  `PatternExtractor`, `AdjacencyRules`, `Grid`, `Wave`, `Bitmask` and `Wfc::PNG`.
  Requiring `wfc` no longer runs the algorithm or prints anything.
- Added the `wfc` command line tool (`exe/wfc`) with options for input PNG, output size,
  pattern size, rotations and seed.
- Propagation now counts supporters per pattern and direction (AC-4, as in Gumin's
  reference implementation): a 50x50 image takes well under a second instead of ~65s.
- Observation picks a pattern weighted by its frequency in the sample.
- `chunky_png` is now a runtime dependency of the gem.

### Fixed

- Pattern probabilities were computed with integer division and were always 0,
  so the entropy was NaN and cells were effectively collapsed in scanline order.
- A contradiction (a cell without any possible pattern) crashed with `NoMethodError`;
  it now raises `Wfc::ContradictionError` internally and generation is retried
  (`max_attempts`), finally raising `Wfc::GenerationFailedError`. A contradiction before
  the first random choice (`Wfc::UnsatisfiableError`) fails right away instead.
- Patterns that can never be supported are removed before the first observation.

## [0.1.0] - 2021-10-14

- Initial release
