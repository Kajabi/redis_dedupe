# RedisDedupe

This is a weak deduper to make things like bulk email run safer. It is not a lock safe for financial/security needs because it uses a weak redis locking pattern that can have race conditions.

However, imagine a bulk email job that loops over 100 users, and enqueues a background email for each user. If the job fails at iteration 50, a retry would enqueue all the users again and many will receive dupes. This would continue multiple times as the parent job continued to rerun. By marking that a subjob has been enqueued, we can let that isolated job handle its own failures, and the batch enqueue job can run multiple times without re-enqueueing the same subjobs. 

## Installation

Add this line to your application's Gemfile:

    gem 'redis_dedupe'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_dedupe

## Usage

```ruby
comment_id = 42
dedupe = RedisDedupe.new($redis, "comment:42:notification")

users.each do |user|
  dedupe.check(user.id) do
    send_email_to(user, comment_id)
  end
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/redis_dedupe/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
