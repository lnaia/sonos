module MonitorSonos
  class Monitor
    attr_reader :speakers

    def initialize
      @logger = MonitorSonos.logger
      @speakers = MonitorSonos.speakers
      @monitor_heartbeat = 10
      @scan_heartbeat = 30
    end

    def self.init
      new.send(:init)
    end

    private
    def init
      Thread.new { discover_speakers }
    end

    def discover_speakers
      sonos = Sonos::System.new
      while true
        @logger.info 'scanning for speakers'
        new_speakers = []
        sonos.speakers.each do |speaker|
          unless @speakers.key?(speaker.ip)
            @logger.info "speaker found: #{speaker.ip}-#{speaker.name}"
            new_speakers << Thread.new { monitor_speaker(speaker) }
          end
        end
        new_speakers.map(&:join)
        sleep @scan_heartbeat
      end
    end

    def monitor_speaker(speaker)
      @logger.info "monitoring speaker: #{speaker.ip}-#{speaker.name}"
      while true
        @speakers[speaker.ip] = {} if @speakers[speaker.ip].nil?
        @speakers[speaker.ip] = {
            raw: speaker,
            name: speaker.name,
            volume: speaker.volume
        }

        if speaker.now_playing.nil?
          @speakers[speaker.ip][:playing] = nil
        elsif is_playing? speaker
          @speakers[speaker.ip][:playing] = speaker.now_playing
        end
        sleep @monitor_heartbeat
      end
    rescue HTTPClient::ConnectTimeoutError
      @speakers.delete speaker.ip
      msg = 'HTTPClient::ConnectTimeoutError while trying to monitor a speaker'
      @logger.error "#{msg} #{speaker.ip}"
    rescue HTTPClient::ReceiveTimeoutError
      @speakers.delete speaker.ip
      msg = 'HTTPClient::ReceiveTimeoutError while trying to monitor a speaker'
      @logger.error "#{msg} #{speaker.ip}"
    rescue HTTPClient::KeepAliveDisconnected
      @speakers.delete speaker.ip
      msg = 'HTTPClient::KeepAliveDisconnected while trying to monitor a speaker'
      @logger.error "#{msg} #{speaker.ip}"
    end

    def is_playing?(sp)
      return false if sp.now_playing.nil?
      artist = sp.now_playing[:artist]
      album = sp.now_playing[:album]
      track_duration = sp.now_playing[:track_duration]
      hours, minutes, seconds = track_duration.split(':').map { |i| i.to_i }
      total_seconds = hours*60*60 + minutes*60 + seconds
      playing = total_seconds > 0 || (artist.length > 0 && album.length > 0)

      playing.tap do
        unless playing
          msg = "#{sp.ip}-#{sp.name} says it is playing but it is not"
          @logger.warn msg
        end
      end
    end
  end
end
