require 'redis'
require 'json'


redis = Redis.new
redis.publish 'testc', { msg: 'this is A' }.to_json
