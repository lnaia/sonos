require 'terminal-table'

class Display
  def show(speaker_info = {}, recent_logs = [])
    headings = %w(ip name volume artist title position)

    while true
      rows = []

      speaker_info.each do |ip, details|
        row = []
        row << ip
        row << details[:name]
        row << details[:volume]

        if details[:playing].nil?
          (0..2).each { row << 'n/a' }
        else
          current = details[:playing][:current_position]
          total = details[:playing][:track_duration]

          row << details[:playing][:artist]
          row << details[:playing][:title]
          row << "#{current}/#{total}"
        end

        rows << row
      end

      # sort by ip
      rows.sort { |a, b| a.first <=> b.first }
      rows << :separator
      rows << ['Recent logs', {value: recent_logs.join("\n"), colspan: 5}]

      system 'clear' or system 'cls'
      title = 'Monitoring Sonos Nodes in current network'
      puts Terminal::Table.new title: title, headings: headings, rows: rows
      sleep 1
    end
  end
end
