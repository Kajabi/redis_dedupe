require 'redis_dedupe'
require 'mock_redis'
require 'spec_helper'

describe RedisDedupe do
  it "is initialized with a redis client and key" do
    dedupe = RedisDedupe.new(:redis, :key)
    expect(dedupe.key).to eq(:key)
  end

  it "defaults expires_in to 7 days" do
    dedupe = RedisDedupe.new(:redis, :key)
    expect(dedupe.expires_in.to_i).to eq((Time.now + (7*24*60*60)).to_i)
  end

  it "optionally receives an expires_in time" do
    dedupe = RedisDedupe.new(:redis, :key, (Time.now + (7*24*60)).to_i)
    expect(dedupe.expires_in.to_i).to eq((Time.now + (7*24*60)).to_i)
  end
end

describe RedisDedupe, "#check" do
  it "prevents a block from yielding multiple times for the same member" do
    dedupe1 = RedisDedupe.new(MockRedis.new, 'spec_key:1')
    dedupe2 = RedisDedupe.new(MockRedis.new, 'spec_key:2')

    @results = []

    dedupe1.check('1') { @results << 'A' }
    dedupe1.check('1') { @results << 'B' }
    dedupe2.check('1') { @results << 'C' }

    expect(@results).to eq(['A', 'C'])
  end

  it "sets the set to expire so it cleans up if the process never completes" do
    redis  = MockRedis.new
    dedupe = RedisDedupe.new(redis, 'spec_key:1', 10)

    dedupe.check('1') {  }

    expect(redis.ttl 'spec_key:1').to be_within(1).of(10)
  end
end

describe RedisDedupe, "#finish" do
  it "removes the set to free up memory" do
    redis  = MockRedis.new
    dedupe = RedisDedupe.new(redis, 'spec_key:1')

    dedupe.check('1') {  }
    dedupe.finish

    expect(redis.exists 'spec_key:1').to be(false)
  end
end
