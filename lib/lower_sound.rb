module MonitorSonos
  class LowerSound
    def initialize
      @speakers = MonitorSonos.speakers
      @logger = MonitorSonos.logger
      @volume_threshold = MonitorSonos.config['volume_threshold']
      @heartbeat = 30
    end

    def self.run(volume_threshold = nil)
      MonitorSonos.logger.info 'MonitorSonos::LowerSound.run'
      MonitorSonos.join(
          MonitorSonos::Monitor.init,
          MonitorSonos::Display.init,
          MonitorSonos::LowerSound.init(volume_threshold)
      )
    end

    def self.init(volume_threshold)
      Thread.new { new.send(:init, volume_threshold) }
    end

    private
    def init(volume_threshold = nil)
      @volume_threshold = volume_threshold unless volume_threshold.nil?
      while true
        @speakers.each do |key, speaker|
          next if speaker[:raw].nil?
          update_volume(speaker[:raw])
        end
        sleep @heartbeat
      end
    end

    def update_volume(speaker)
      current_volume = speaker.volume.to_i
      return unless current_volume > @volume_threshold
      speaker.volume = current_volume-1
      msg = "volume set to #{speaker.volume}: #{speaker.ip}-#{speaker.name}"
      @logger.info msg
    end
  end
end