module MonitorSonos
  # :nodoc:
  class MonitorMusic
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
        tracks = []
        speakers.each do |_, details|
          details = JSON.parse(details)
          tracks << get_track(details) unless details['playing'].nil?
        end
        save_tracks tracks.uniq unless tracks.empty?
        sleep @heartbeat
      end
    end

    def get_track(details)
      playing = details['playing']
      artist = playing['artist']
      title = playing['title']
      album = playing['album']
      "#{artist}, #{album}, #{title}"
    end

    def save_tracks(list)
      File.read(logfile).split("\n").each do |track|
        track = track.strip.match(/\d{4}-\d{2}-\d{2} (.+)/).to_a.last
        list.delete track unless track.nil?
      end
      list.map! { |m| "#{Time.now.strftime '%Y-%m-%d'} #{m}" }
      update_tracks_file(list)
    end

    def update_tracks_file(list)
      return if list.empty?
      File.open(logfile, 'a') { |file| file.write("#{list.join("\n")}\n") }
    end

    def speakers
      Redis.new.hgetall('h_speakers')
    end

    def logger
      MonitorSonos.logger
    end

    def logfile
      "#{MonitorSonos.root}/logs/music.log"
    end
  end
end
