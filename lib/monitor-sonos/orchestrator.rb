# :nodoc:
module MonitorSonos
  # :nodoc:
  class Orchestrator

    def initialize
      #
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
      MonitorSonos::Discovery.init
      MonitorSonos::MonitorNode.init
      MonitorSonos::Display.init
      orchestrator
    end

    def orchestrator
      #
    end


    def logger
      MonitorSonos.logger
    end
  end
end
