require 'spec_helper'
require 'dedupe_set'

describe DedupeSet do
  it "is initialized with a redis client and key" do
    dedupe = DedupeSet.new(:redis, :key)
    expect(dedupe.key).to eq(:key)
  end
end
