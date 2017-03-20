module MonitorSonos
  class MonitorMusic
    def initialize
      @speakers = MonitorSonos.speakers
      @logfile = "#{MonitorSonos.root}/logs/music.log"
      @logger = MonitorSonos.logger
      @heartbeat = 5
    end

    def self.init
      Thread.new { new.send(:init) }
    end

    private
    def init
      while true
        tracks = []
        @speakers.each do |ip, details|
          next if details[:playing].nil?
          artist = details[:playing][:artist]
          title = details[:playing][:title]
          album = details[:playing][:album]
          tracks << "#{artist}, #{album}, #{title}"
        end
        save_tracks tracks.uniq
        sleep @heartbeat
      end
    rescue => ex
      @logger.error ex.message
    end

    def save_tracks(_list)
      time = Time.now.strftime '%Y-%m-%d'
      @logger.debug "#{__method__} count: #{_list.count}"
      return if _list.empty?

      File.read(@logfile).split("\n").each do |track|
        tr = track.strip
        track = tr.match(/\d{4}-\d{2}-\d{2} (.+)/).to_a.last
        next if track.nil?
        _list.delete track
      end

      _list.map! { |m| "#{time} #{m}" }
      return if _list.empty?
      File.open(@logfile, 'a') { |file| file.write("#{_list.join("\n")}\n") }
    end
  end
end
