require 'dedupe_set/version'

class DedupeSet
  attr_reader :key, :expires_in

  def initialize(redis, key, expires_in = (Time.now + (2*7*24*60*60)))
    @redis      = redis
    @key        = key
    @expires_in = expires_in
  end

  def check(member)
    results = redis.pipelined do
      redis.sadd key, member
      redis.expire key, expires_in
    end

    if results[0]
      yield
    end
  end

  def finish
    redis.del key
  end

  private

  def redis
    @redis
  end
end
