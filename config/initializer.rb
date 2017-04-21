Dir['./lib/**/*.rb'].each { |f| require f }

Redis.current = Redis.new(host: '127.0.0.1', port: '6379')
