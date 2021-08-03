# frozen_string_literal: true

module RedisDedupe
  class << self
    attr_accessor :client
  end

  # A mechanism to make sure that a block of code will only be called once for each specified identifier (or +member+)
  # even if the calling process dies or restarts, as long the datastore is +Redis+-backed.
  #
  # @example Keep the set around for 7 days, letting Redis handle its own memory cleanup after that time
  #   ```
  #   dedupe = RedisDedupe::Set.new($redis, "send_payment_due_emails")
  #   Account.all do |account|
  #     dedupe.check(account.id) do
  #       mail(to: account.billing_email, subject: "PAY US... NOW!!!")
  #     end
  #   end
  #   ```
  #
  # @example If you want to be able to repeat the process at any time immediately following this method
  #   ```
  #   dedupe = RedisDedupe::Set.new($redis, "send_welcome_emails")
  #   Account.all.pluck(:email) do |email|
  #     dedupe.check(email) { mail(to: email, subject: "Hello!") }
  #   end
  #   dedupe.finish
  #   ```
  #
   class Set
    SEVEN_DAYS = 7 * 24 * 60 * 60

    attr_reader :key, :expires_in

    def initialize(redis, key, expires_in = SEVEN_DAYS)
      @redis      = redis
      @key        = key
      @expires_in = expires_in
    end

    # Ensures that a block of code will only be run if the +member+ is not already contained in Redis.
    # ie: the code block has not already run for the specified +member+.
    #
    # @param [String, Integer] member identifiying value to make sure the given block only runs once
    #
    # @return `nil` if the block was not run, otherwise the result of the yielded block
    #
    def check(member)
      results = redis.pipelined do
        redis.sadd(key, member)
        redis.expire(key, expires_in)
      end

      return nil unless block_given? && results[0] # `results` will be `[true]` or `[false]`

      yield
    end

    def finish
      redis.del(key)
    end

    private

    def redis
      @redis
    end
  end
end
