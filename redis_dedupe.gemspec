# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_dedupe/version'

Gem::Specification.new do |spec|
  spec.name          = "redis_dedupe"
  spec.version       = RedisDedupe::VERSION
  spec.authors       = ["Andy Huynh"]
  spec.email         = ["andy4thehuynh@gmail.com"]
  spec.summary       = %q{ A weak deduper to make things like bulk email run safer. }
  spec.description   = %q{ This is a weak deduper to make things like bulk email run safer. It is not a lock safe for financial/security needs because it uses a weak redis locking pattern that can have race conditions. However, imagine a bulk email job that loops over 100 users, and enqueues a background email for each user. If the job fails at iteration 50, a retry would enqueue all the users again and many will receive dupes. This would continue multiple times as the parent job continued to rerun. By marking that a subjob has been enqueued, we can let that isolated job handle its own failures, and the batch enqueue job can run multiple times without re-enqueueing the same subjobs. }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "mock_redis"
  spec.add_development_dependency "pry"
end
