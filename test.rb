require 'celluloid/current'

class Animal
  attr_accessor :threads

  def run
    th = Thread.new { stuff }
    @threads << th
  end

  def stuff
    loop do
      puts "animal says stuff!"
      sleep 1
    end
  end
end

class Test

  def initialize
    @joined = []
    @threads = []
  end

  def controller
    loop do
      puts "running: #{__method__}"
      @joined.each do |th|
        th.run
        sleep 1
        th.stop
      end
      sleep 1
    end
  end

  def watcher
    loop do
      puts "running: #{__method__}"
      th = @threads.pop
      @joined << th.join
      sleep 1
    end
  end

  def run
    @threads << Thread.new { watcher }
    @threads << Thread.new { cc }
    a = Animal.new
    a.threads = @threads
    a.run
    controller
  end

  def cc
    puts "running: #{__method__}"
    2.times do
      @threads << Thread.new { dynamic(rand(100)) }
    end
  end

  def dynamic(id)
    loop do
      puts "dynamic thread: #{id}\n"
      sleep 1
    end
  end

end


t = Test.new
t.run
