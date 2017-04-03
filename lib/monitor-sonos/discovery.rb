module MonitorSonos
  # :nodoc:
  class Discovery

    def initialize
      @heartbeat = 30
    end

    def self.init
      new.send(:init)
    end

    private

    def init
      Thread.new { run }.join
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
