#
# Setup Redis
#
require 'redis'
require 'redis/namespace'
require 'redisted'
begin
  redis_nons=Redis.new({
    host: "localhost",
    port: 6379,
    timeout: 5,
  })
  $redis=Redis::Namespace.new(:mmtest,redis: redis_nons)
  Redisted::Base.redis=$redis
rescue =>err
  puts "MessageManage redis error: #{err}"
  raise "MessageManage redis error: #{err}"
end
