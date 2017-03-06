module MonitorSonos
  class MonitorMusic
    def initialize
      @speakers = MonitorSonos.speakers
      @logfile = "#{MonitorSonos.root}/logs/music.log"
      @logger = MonitorSonos.logger
      @heartbeat = 30
    end

    def self.init
      Thread.new { new.send(:init) }
    end

    private
    def init
      while true
        musics = []
        @speakers.each do |ip, details|
          next if details[:playing].nil?
          artist = details[:playing][:artist]
          title = details[:playing][:title]
          album = details[:playing][:album]
          musics << "#{artist}, #{album}, #{title}"
        end
        save_music musics.uniq
        sleep @heartbeat
      end
    rescue => ex
      @logger.error ex.message
    end

    def exists?(string)
      @logger.debug "exists? #{string}"
      exists = false
      File.readlines(@logfile).each do |line|
        line = line.strip
        @logger.debug "searching #{line}"
        if line.match(/\d+-\d+-\d+ #{string}/)
          @logger.debug 'match found'
          exists = true
          break
        end
      end
      exists
    end

    def save_music(musics)
      time = Time.now.strftime '%Y-%m-%d'
      lines = musics.map { |m| "#{time} #{m}" unless exists? m }.compact
      return if lines.empty?
      File.open(@logfile, 'a') { |file| file.write("#{lines.join("\n")}\n") }
    end
  end
end
