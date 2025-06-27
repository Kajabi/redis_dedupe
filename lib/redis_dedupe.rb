require 'redis_dedupe/version'

module RedisDedupe
  class<<self
    attr_accessor :client
  end

  class Set
    SEVEN_DAYS = 7 * 24 * 60 * 60
    DEFAULT_EXPIRES_IN = SEVEN_DAYS

    attr_reader :key, :expires_in

    def initialize(redis, key, expires_in = DEFAULT_EXPIRES_IN)
      @redis = redis
      @key = key
      @expires_in = expires_in
    end

    def check(member)
      results = redis.pipelined do |pipeline|
        pipeline.sadd?(key, member)
        pipeline.expire(key, expires_in)
      end

      if results[0]
        yield
      end
    end

    def finish
      redis.unlink(key)
    end

    private

    def redis
      @redis
    end
  end

  module Helpers
    private

    def dedupe
      @dedupe ||=
        RedisDedupe::Set.new(
          RedisDedupe.client,
          [dedupe_namespace, dedupe_id].join(':'),
          dedupe_expires_in,
        )
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

    # Override in class if needed, should return an integer representing the
    # number of seconds until expiry.
    #
    # Ex.
    #
    #   def dedupe_expires in
    #     24 * 60 * 60 # => Or can use e.g. `1.day` in Rails.
    #   end
    #
    def dedupe_expires_in
      RedisDedupe::Set::DEFAULT_EXPIRES_IN
    end

    def dedupe_namespace
      self.class.name
    end
  end
end
