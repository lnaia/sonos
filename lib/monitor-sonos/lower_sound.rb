module MonitorSonos
  # :nodoc:
  class LowerSound
    def initialize
      @volume_threshold = MonitorSonos.config['volume_threshold']
      @minimum_volume = MonitorSonos.config['minimum_volume']
      @heartbeat = 30
    end

    def self.init(volume_threshold)
      new.send(:init, volume_threshold)
    end

    private

    def init(volume_threshold)
      init_volume_threshold(volume_threshold)
      run
    end

    def init_volume_threshold(volume_threshold = nil)
      return if volume_threshold.nil?
      volume_threshold = volume_threshold.to_i
      return unless volume_threshold > 0
      @volume_threshold = volume_threshold
      logger.info "volume_threshold set to #{@volume_threshold}"
    end

    def run
      loop do
        speakers.each { |speaker| update_volume(speaker) }
        sleep @heartbeat
      end
    end

    def update_volume(speaker)
      current_volume = speaker.volume.to_i
      return unless current_volume > @volume_threshold
      speaker.volume = current_volume - 1
      msg = "volume set to #{speaker.volume}: #{speaker.ip}, #{speaker.name}"
      logger.info msg
    end

    def speakers
      Sonos::System.new.speakers
    end

    def logger
      MonitorSonos.logger
    end
  end
end
