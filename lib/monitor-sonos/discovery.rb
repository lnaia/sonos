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
      run
    end

    def run
      loop do
        discover
        sleep @heartbeat
      end
    end

    def discover
      speakers = sonos.speakers
      logger.info "found #{speakers.length} speakers in the network"
      speakers.each { |speaker| publish(speaker) }
    end

    def publish(speaker)
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
