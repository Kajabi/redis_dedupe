require 'redis_dedupe'
require 'mock_redis'
require 'spec_helper'

describe RedisDedupe::Set do
  it "is initialized with a redis client and key" do
    dedupe = RedisDedupe::Set.new(:redis, :key)
    expect(dedupe.key).to eq(:key)
  end

  it "defaults expires_in to 7 days" do
    dedupe = RedisDedupe::Set.new(:redis, :key)
    expect(dedupe.expires_in.to_i).to eq(7 * 24 * 60 * 60)
  end

  it "optionally receives an expires_in seconds value" do
    dedupe = RedisDedupe::Set.new(:redis, :key, 60)
    expect(dedupe.expires_in.to_i).to eq(60)
  end
end

describe RedisDedupe::Set, "#check" do
  it "prevents a block from yielding multiple times for the same member" do
    dedupe1 = RedisDedupe::Set.new(MockRedis.new, 'spec_key:1')
    dedupe2 = RedisDedupe::Set.new(MockRedis.new, 'spec_key:2')

    @results = []

    dedupe1.check('1') { @results << 'A' }
    dedupe1.check('1') { @results << 'B' }
    dedupe2.check('1') { @results << 'C' }

    expect(@results).to eq(['A', 'C'])
  end

  it "sets the set to expire so it cleans up if the process never completes" do
    redis  = MockRedis.new
    dedupe = RedisDedupe::Set.new(redis, 'spec_key:1', 10)

    dedupe.check('1') {  }

    expect(redis.ttl 'spec_key:1').to be_within(1).of(10)
  end
end

describe RedisDedupe::Set, "#finish" do
  it "removes the set to free up memory" do
    redis  = MockRedis.new
    dedupe = RedisDedupe::Set.new(redis, 'spec_key:1')

    dedupe.check('1') {  }
    dedupe.finish

    expect(redis.exists 'spec_key:1').to be(0)
  end
end
