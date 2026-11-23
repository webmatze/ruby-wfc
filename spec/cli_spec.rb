# frozen_string_literal: true

require "open3"
require "tmpdir"
require "wfc/png"

RSpec.describe "exe/wfc" do
  let(:exe) { File.expand_path("../exe/wfc", __dir__) }
  let(:lib) { File.expand_path("../lib", __dir__) }

  def run_cli(*args)
    Open3.capture3(RbConfig.ruby, "-I", lib, exe, *args)
  end

  it "writes a PNG of the requested size" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "out.png")
      stdout, _stderr, status = run_cli("--seed", "1", "-s", "12x8", "-o", path)

      expect(status).to be_success
      expect(stdout).to include("Wrote 12x8 image")
      expect(Wfc::PNG.load(path).map(&:length)).to eq([12] * 8)
    end
  end

  it "reports invalid options without a stack trace" do
    _stdout, stderr, status = run_cli("-s", "50")

    expect(status.exitstatus).to eq(1)
    expect(stderr).to eq("wfc: invalid argument: -s 50\n")
  end
end
