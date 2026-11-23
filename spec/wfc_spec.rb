# frozen_string_literal: true

RSpec.describe Wfc do
  it "has a version number" do
    expect(Wfc::VERSION).not_to be_nil
  end

  it "has no side effects when required" do
    output = `#{RbConfig.ruby} -Ilib -e 'require "wfc"' 2>&1`
    expect(output).to be_empty
  end
end
