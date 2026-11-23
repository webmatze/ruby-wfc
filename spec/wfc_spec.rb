# frozen_string_literal: true

require "open3"

RSpec.describe Wfc do
  it "has a version number" do
    expect(Wfc::VERSION).not_to be_nil
  end

  it "has no side effects when required" do
    lib = File.expand_path("../lib", __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, "-I", lib, "-e", 'require "wfc"')

    expect(status).to be_success
    expect(output).to be_empty
  end
end
