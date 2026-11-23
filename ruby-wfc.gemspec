# frozen_string_literal: true

require_relative "lib/wfc/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby-wfc"
  spec.version       = Wfc::VERSION
  spec.authors       = ["Mathias Karstädt"]
  spec.email         = ["mathias.karstaedt@gmail.com"]

  spec.summary       = "Ruby implementation of wave function collapse algorithm"
  spec.description   = "Generates images from a small sample using the overlapping Wave Function Collapse model."
  spec.homepage      = "https://github.com/webmatze/ruby-wfc"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "chunky_png", "~> 1.4"
end
