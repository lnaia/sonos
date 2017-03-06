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
      existing = File.read(@logfile).map{|l| l.strip}.compact
      tracks = _list.map { |m| "#{time} #{m}" } - existing
      return if tracks.empty?
      File.open(@logfile, 'a') { |file| file.write("#{tracks.join("\n")}\n") }
    end
  end
end
