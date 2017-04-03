module MonitorSonos
  # :nodoc:
  class Display

    def initialize
      @heartbeat = 1
    end

    def self.init
      new.send(:init)
    end

    private

    def init
      Thread.new { run }
    end

    def run
      headings = %w(ip name volume artist title position)
      loop do
        logger.info 'display'
        @rows = []
        add_speaker_rows
        system('clear') || system('cls')
        title = 'Monitoring Sonos Nodes in current network'
        puts Terminal::Table.new title: title, headings: headings, rows: @rows
        sleep @heartbeat
      end
    end

    def add_speaker_rows
      speakers.each do |ip, details|
        @rows << add_speaker_row(ip, details)
      end
      @rows.sort_by(&:first) # sort by ip
    end

    def add_speaker_row(ip, details)
      row = []
      row << ip
      row << details[:name]
      row << details[:volume]
      row << playing_rows(details)
      row.flatten
    end

    def playing_rows(details)
      if details[:playing].nil?
        %w(n/a n/a n/a)
      else
        [
          details[:playing][:artist].to_s.slice(0, 20),
          details[:playing][:title].to_s.slice(0, 20),
          track_status(details)
        ]
      end
    end

    def track_status(details)
      current = details[:playing][:current_position]
      total = details[:playing][:track_duration]
      "#{current}/#{total}"
    end

    def logger
      MonitorSonos.logger
    end

    def speakers
      MonitorSonos.speakers
    end
  end
end
