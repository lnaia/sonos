module MonitorSonos
  class MonitorMusic
    def initialize
      @speakers = MonitorSonos.speakers
      @logfile = "#{MonitorSonos.root}/logs/music.log"
      @logger = MonitorSonos.logger
      @music_logger ||= music_logger
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
          music = "#{artist}, #{album}, #{title}"
          musics << music unless musics.include? music
        end
        musics.each { |m| @music_logger.info(m) unless exists?(m) }
        sleep @heartbeat
      end
    end

    def exists?(string)
      @logger.debug "exists? #{string}"
      exists = false
      File.readlines(@logfile).each do |line|
        line = line.strip
        @logger.debug "searching #{line}"
        if line.match(/#{string}/)
          @logger.debug 'match found'
          exists = true
          break
        end
      end
      exists
    end

    def music_logger
      FileUtils.touch @logfile unless File.exist? @logfile
      Logger.new(@logfile, 'daily').tap do |l|
        l.formatter = proc do |severity, datetime, progname, msg|
          date_format = datetime.strftime '%Y-%m-%d %H:%M:%S '
          "#{date_format} #{msg}\n"
        end
      end
    end
  end
end