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
      sonos.speakers.each { |speaker| publish(speaker) }
    end

    def publish(speaker)
      logger.info "speaker found at #{speaker.ip}"
      redis.publish 'c_speakers', { uid: speaker.uid }.to_json
    end

    def redis
      Redis.new
    end

    def logger
      MonitorSonos.logger
    end

    def sonos
      @sonos ||= Sonos::System.new
    end
  end
end
