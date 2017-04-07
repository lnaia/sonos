require 'celluloid/current'

class Test
  include Celluloid

  def initialize
    @threads = []
  end

  def aa
    Thread.new {
      sleep 2
      puts 'a'

    }
  end

  def bb
    Thread.new {
      sleep 1
      puts 'b'
    }
  end

# every 5 seconds, spawns 2 threads
  def cc
    threads = []
    puts 'cc'
    2.times do
      threads << Thread.new { dynamic(rand(100)) }
    end
    threads.map(&:join)
    sleep 3

    2.times do
      threads << Thread.new { dynamic(rand(100)) }
    end
  end

  def dynamic(id)
    loop do
      puts "dynamic thread: #{id}\n"
      sleep 1
    end
  end
end

mailer_pool = Test.pool(size: 3)
100.times do |id|
  mailer_pool.async.dynamic(id)
end

