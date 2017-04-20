module MonitorSonos
  # :nodoc:
  class MonitorNode
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
        new_speakers = monitored - speakers
        logger.info "new speakers: #{new_speakers}" unless new_speakers.empty?
        new_speakers.each { |ip| handle_new_speaker(ip) }
        sleep @heartbeat
      end
    end

    def handle_new_speaker(ip)
      Process.fork do
        Process.detach Process.pid
        init_monitor(ip)
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
      th = monitor_threads[speaker_ip]
      Thread.kill(th)
      monitor_threads.delete th
      MonitorSonos.threads.delete th
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
      @monitored ||= []
    end

    def speakers
      redis.get(:speakers) || []
    end

    def redis
      Redis.current
    end

    def logger
      MonitorSonos.logger
    end
  end
end
