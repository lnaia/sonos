class Display
  def display_info
    headings = %w(ip name volume artist title position)

    while true
      rows = []

      @speaker_info.each do |ip, details|
        row = []
        row << ip
        row << details[:name]
        row << details[:volume]

        if details[:playing].nil?
          (0..2).each { row << 'n/a' }
        else
          row << details[:playing][:artist]
          row << details[:playing][:title]
          row << "#{details[:playing][:current_position]} / #{details[:playing][:track_duration]}"
        end

        rows << row
      end

      # sort by ip
      rows.sort { |a, b| a.first <=> b.first }
      rows << :separator
      rows << ['Recent logs', {value: @recent_logs.join("\n"), colspan: 5}]

      system 'clear' or system 'cls'
      title = 'Monitoring Sonos Nodes in current network'
      puts Terminal::Table.new title: title, headings: headings, rows: rows
      sleep 1
    end
  end
end
