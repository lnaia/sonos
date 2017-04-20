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
      run
    end

    def run
      headings = %w(name volume artist title position)
      loop do
        @rows = []
        add_speaker_rows
        system('clear') || system('cls')
        title = 'Monitoring Sonos Nodes in current network'
        puts Terminal::Table.new title: title, headings: headings, rows: @rows
        sleep @heartbeat
      end
    end

    def add_speaker_rows
      speakers.each do |_, details|
        details = JSON.parse(details)
        @rows << add_speaker_row(details)
      end
      @rows.sort_by(&:first) # sort by ip
    end

    def add_speaker_row(details)
      row = []
      row << details['name']
      row << details['volume']
      row << playing_rows(details)
      row.flatten
    end

    def playing_rows(details)
      if details['playing'].nil?
        %w(n/a n/a n/a)
      else
        [
          details['playing']['artist'].to_s.slice(0, 20),
          details['playing']['title'].to_s.slice(0, 20),
          track_status(details)
        ]
      end
    end

    def track_status(details)
      current = details['playing']['current_position']
      total = details['playing']['track_duration']
      "#{current}/#{total}"
    end

    def logger
      MonitorSonos.logger
    end

    def speakers
      Redis.new.hgetall('h_speakers')
    end
  end
end
