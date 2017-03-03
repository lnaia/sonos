module MonitorSonos
  class Display
    def initialize
      @speakers = MonitorSonos.speakers
    end

    def self.init
      Thread.new { new.send(:init) }
    end

    private
    def init
      headings = %w(ip name volume artist title position)
      while true
        @rows = []
        add_speaker_rows
        system 'clear' or system 'cls'
        title = 'Monitoring Sonos Nodes in current network'
        puts Terminal::Table.new title: title, headings: headings, rows: @rows
        sleep 1
      end
    end

    def add_speaker_rows
      @speakers.each do |ip, details|
        row = []
        row << ip
        row << details[:name]
        row << details[:volume]

        if details[:playing].nil?
          (0..2).each { row << 'n/a' }
        else
          current = details[:playing][:current_position]
          total = details[:playing][:track_duration]

          row << "#{details[:playing][:artist]}".slice(0, 20)
          row << "#{details[:playing][:title]}".slice(0, 20)
          row << "#{current}/#{total}"
        end
        @rows << row
      end
      @rows.sort { |a, b| a.first <=> b.first } # sort by ip
    end
  end
end