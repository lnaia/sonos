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
      MonitorSonos.subscribe('c_speakers') do |on|
        on.message do |_, msg|
          data = JSON.parse(msg)
          uid = data['uid']
          handle_new_speaker(uid) unless uid.nil?
        end
      end
    end

    def handle_new_speaker(uid)
      return if monitoring? uid
      Process.fork do
        Process.detach(Process.pid)
        init_monitor(uid)
      end
    end

    def init_monitor(uid)
      logger.info "monitoring speaker: #{uid}"
      loop do
        monitor(uid)
        sleep @heartbeat
      end
    rescue => ex
      logger.error "Exception at speaker [#{uid}] #{ex.message}"
      ap ex
    end

    def monitor(uid)
      speakers.each do |speaker|
        next unless speaker.uid == uid
        save(uid,
             name: speaker.name,
             ip: speaker.ip,
             volume: speaker.volume,
             monitor_pid: Process.pid,
             playing: playing?(speaker) ? speaker.now_playing : nil)
      end
    end

    def playing?(speaker)
      return false if speaker.now_playing.nil?
      hours, minutes, seconds = track_duration(speaker)
      total_seconds = hours * 60 * 60 + minutes * 60 + seconds
      total_seconds > 0 || (artist?(speaker) && album?(speaker))
    end

    def monitoring?(uid)
      json_data = MonitorSonos.speakers(uid)
      return false if json_data.nil?
      data = JSON.parse(json_data)
      pid = data['monitor_pid'].to_s.strip
      exists = `ps -p #{pid} -o pid | grep #{pid}`
      exists.strip == pid
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

    def save(key, data)
      MonitorSonos.save_speaker(key, data)
    end

    def logger
      MonitorSonos.logger
    end

    def speakers
      Sonos::System.new.speakers
    end
  end
end
