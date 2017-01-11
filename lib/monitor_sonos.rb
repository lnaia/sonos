require_relative "monitor"
require_relative "persistence"
require_relative "display"
require_relative "sonos_logger"

class MonitorSonos
  def initialize
    @logger = SonosLogger.new
    @display = Display.new
    @persistence = Persistence.new(@logger)
    @monitor = Monitor.new(@logger, @persistence)    
  end

  def run
    threads = @monitor.prepare_threads
    threads << Thread.new do
      @display.show(@monitor.speaker_info, @logger.recent_logs)
    end

    @logger.log('initialize threaded monitoring')
    threads.map(&:join)
  end
end
