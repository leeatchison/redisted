#
# Setup Redis
#
require 'redis'
require 'redisted'
begin
  $redis=Redis.new({
    host: "localhost",
    port: 6379,
    timeout: 5,
  })
  $redis.select 15 # Database #15
  Redisted::Base.redis=$redis
rescue =>err
  puts "MessageManage redis error: #{err}"
  raise "MessageManage redis error: #{err}"
end
