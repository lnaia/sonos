def aa
  Thread.new {
    puts 'a'
    sleep 1
  }
end

def bb
  Thread.new {
    puts 'b'
    sleep 1
  }
end

# every 5 seconds, spawns 2 threads
def cc
  puts 'cc'
  loop do
    2.times do
      Thread.new { dynamic(rand(100)) }.join
    end
    sleep 5
  end
end

def dynamic(id)
  loop do
    puts "dynamic thread: #{id}"
    sleep 1
  end
end

t = []
t << aa
cc
t << bb
t.map(&:join)



