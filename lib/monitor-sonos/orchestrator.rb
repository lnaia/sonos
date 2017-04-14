# :nodoc:
module MonitorSonos
  # :nodoc:
  class Orchestrator
    attr_accessor :threads

    def initialize
      @threads = Queue.new
      @joined ||= Queue.new
    end

    def self.monitor
      new.send(:monitor)
    end

    def self.lower_sound
      new.send(:monitor)
    end

    private

    def monitor
      #logger.info "running: #{__method__}"
      MonitorSonos::Discovery.init(@threads)
      MonitorSonos::MonitorNode.init(@threads)
      MonitorSonos::Display.init(@threads)
      orchestrator
    end

    def orchestrator
      watcher
      loop do
        logger.info "#{__method__}, @joined: #{@joined.length}"

        queue = Queue.new
        until @joined.empty?
          th = @joined.pop
          th.run
          sleep 1
          th.stop
          queue << th
        end
        @joined = queue

        sleep 1
      end
    end

    def watcher
      th = Thread.new do
        loop do
          logger.info "#{__method__}, @threads: #{@threads.length}"
          @joined << @threads.pop.join
          sleep 1
        end
      end
      @threads << th
    end

    def logger
      MonitorSonos.logger
    end
  end
end
