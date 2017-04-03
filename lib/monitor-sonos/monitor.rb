module MonitorSonos
  # :nodoc:
  class Monitor
    def initialize
      @heartbeat = 15
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
        new_speakers = monitored.keys - speakers.keys
        new_speakers.each do |speaker_ip|
          thread = Thread.new { init_monitor(speaker_ip) }.join
          monitor_threads[speaker_ip] = thread
        end
        sleep @heartbeat
      end
    end

    def init_monitor(speaker_ip)
      logger.info "monitoring speaker: #{speaker_ip}"
      loop do
        monitor(speaker_ip)
        sleep @heartbeat
      end
    rescue => ex
      reset_monitor(speaker_ip)
      logger.error "Exception at speaker [#{speaker_ip}] #{ex.message}"
    end

    def monitor(speaker_ip)
      speaker = Sonos::System.new(speaker_ip)
      speakers[speaker.ip] = {
        raw: speaker,
        name: speaker.name,
        volume: speaker.volume,
        playing: playing?(speaker) ? speaker.now_playing : nil
      }
      monitored[speaker_ip] = true
    end

    def reset_monitor(speaker_ip)
      speakers.delete speaker_ip
      monitored.delete speaker_ip
      Thread.kill(monitor_threads[speaker_ip])
      monitor_threads.delete speaker_ip
      logger.info "monitor reset: #{speaker_ip}"
    end

    def playing?(speaker)
      return false if speaker.now_playing.nil?
      hours, minutes, seconds = track_duration(speaker)
      total_seconds = hours * 60 * 60 + minutes * 60 + seconds
      total_seconds > 0 || (artist?(speaker) && album?(speaker))
    end

    def track_duration(speaker)
      speaker.now_playing[:track_duration].split(':').map(&:to_i)
    end

    def artist?(speaker)
      !speaker.now_playing[:artist].empty?
    end

    def album?(speaker)
      !speaker.now_playing[:album].empty?
    end

    def monitored
      @monitored ||= {}
    end

    def monitor_threads
      @monitor_threads ||= {}
    end

    def speakers
      MonitorSonos.speakers
    end

    def logger
      MonitorSonos.logger
    end
  end
end
