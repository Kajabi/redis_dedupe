# frozen_string_literal: true

require "mock_redis"
require "spec_helper"

require "redis_dedupe/helpers"

RSpec.describe RedisDedupe::Helpers do
  class MyRedisDedupeTestClass
    include RedisDedupe::Helpers

    attr_reader :counter

    def initialize
      @counter = 0
    end

    def test_call
      dedupe.check(5) { @counter += 1 }
      dedupe.check(5) { @counter += 1 }
      dedupe.check(7) { @counter += 1 }
    end

    def dedupe_id
      "just_a_test"
    end
  end

  let(:redis)     { MockRedis.new }
  let(:instance)  { MyRedisDedupeTestClass.new }

  before do
    allow(RedisDedupe).to receive(:client).and_return(redis)
  end

  describe "#dedupe" do
    subject { instance.test_call }

    it { expect { subject }.to change(instance, :counter).from(0).to(2) }

    it "uses the correct redis key" do
      subject
      expect(redis.smembers("MyRedisDedupeTestClass:just_a_test")).to match_array(["5", "7"])
    end
  end
end
