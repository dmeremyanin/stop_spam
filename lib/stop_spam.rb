require "time"
require "httparty"
require "redis-namespace"

require "stop_spam/config"
require "stop_spam/ip"
require "stop_spam/middleware"
require "stop_spam/version"

module StopSpam
  extend self

  delegate :exists, to: :redis
  alias_method :appears?, :exists

  def process(id)
    StopSpam::IP.appears?(id) && add(id) if active?
  end

  def add(id)
    redis.setex id, config.expiration, Time.now
    true
  end

  def keys
    k   = redis.keys
    k.zip redis.mget(*k)
  end

  def config
    @_config ||= Config.new
  end

  def configure
    config.instance_eval &Proc.new
  end

  def redis
    @_redis ||= Redis::Namespace.new config.namespace, redis: config.redis
  end

  def active?
    !!config.active
  end
end

StopSpam.configure do |config|
  config.active = true
  config.expiration = 1.hour
  config.middleware_message = "StopSpam: blocked"
  config.namespace = "stop:spam"
end