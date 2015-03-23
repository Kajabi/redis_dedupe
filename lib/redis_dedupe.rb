require 'redis_dedupe/version'

module RedisDedupe
  class<<self
    attr_accessor :client
  end

  class Set
    SEVEN_DAYS = 7 * 24 * 60 * 60

    attr_reader :key, :expires_in

    def initialize(redis, key, expires_in = Time.now + SEVEN_DAYS)
      @redis      = redis
      @key        = key
      @expires_in = expires_in
    end

    def check(member)
      results = redis.pipelined do
        redis.sadd(key, member)
        redis.expire(key, expires_in)
      end

      if results[0]
        yield
      end
    end

    def finish
      redis.del(key)
    end

    private

    def redis
      @redis
    end
  end

  module Helpers
    private

    def dedupe
      @dedupe ||= RedisDedupe::Set.new(RedisDedupe.client, [dedupe_namespace, dedupe_id].join(':'))
    end

    # Implement in class, should return an integer or string:
    #
    # Ex.
    #
    #   def dedupe_id
    #     @announcement.id # => 42
    #   end
    #
    def dedupe_id
      raise NotImplementedError
    end

    def dedupe_namespace
      self.class.name
    end
  end
end
