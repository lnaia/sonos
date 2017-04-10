module MonitorSonos
  # :nodoc:
  class Discovery

    def initialize
      @heartbeat = 5
    end

    def self.init(threads)
      new.send(:init, threads)
    end

    private

    def init(threads)
      threads << Thread.new { run }
    end

    def run
      loop do
        discover
        sleep @heartbeat
      end
    end

    def discover
      logger.info 'scanning for speakers'
      sonos.speakers.each do |speaker|
        unless speakers.key?(speaker.ip)
          logger.info "speaker found at: #{speaker.ip}"
          speakers[speaker.ip] = {}
        end
      end
    end

    def logger
      MonitorSonos.logger
    end

    def speakers
      MonitorSonos.speakers
    end

    def sonos
      @sonos ||= Sonos::System.new
    end
  end
end
