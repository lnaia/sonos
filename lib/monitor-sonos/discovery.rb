module MonitorSonos
  # :nodoc:
  class Discovery

    def initialize
      @heartbeat = 5
    end

    def self.init
      new.send(:init)
    end

    private

    def init
      run
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
        unless speakers.include?(speaker.ip)
          logger.info "speaker found at: #{speaker.ip}"
          register(speaker.ip)
        end
      end
    end

    def register(ip)
      existing_speakers = speakers
      existing_speakers << ip
      redis.set('speakers', existing_speakers)
    end

    def logger
      MonitorSonos.logger
    end

    def speakers
      redis.get('speakers') || []
    end

    def redis
      Redis.current
    end

    def sonos
      @sonos ||= Sonos::System.new
    end
  end
end
