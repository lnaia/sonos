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
      loop do
        discover
        sleep @heartbeat
      end
    end

    def discover
      Sonos::System.new.speakers.each do |speaker|
        MonitorSonos.publish(uid: speaker.uid)
      end
    end
  end
end
