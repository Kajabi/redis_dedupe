require 'redis_dedupe/version'

class RedisDedupe
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
