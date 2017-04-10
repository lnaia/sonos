# :nodoc:
module MonitorSonos
  # :nodoc:
  class Orchestrator
    attr_accessor :threads

    def initialize
      @threads = []
      @joined_threads ||= []
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
      @threads << Thread.new { watcher }
      MonitorSonos::Discovery.init(@threads)
      MonitorSonos::MonitorNode.init(@threads)
      MonitorSonos::Display.init(@threads)
      orchestrator
    end

    def orchestrator
      loop do
        #logger.info "running: #{__method__}"
        @joined_threads.each do |th|
          th.run
          sleep 1
          th.stop
        end
        sleep 1
      end
    end

    def watcher
      loop do
        #logger.info "running: #{__method__}"
        th = @threads.pop
        @joined_threads << th.join
        sleep 1
      end
    end

    def logger
      MonitorSonos.logger
    end
  end
end
