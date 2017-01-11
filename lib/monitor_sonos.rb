require 'rubygems'
require 'sonos'
require 'terminal-table'
require 'digest/md5'
require 'json'
require 'syslog/logger'

class MonitorSonos

  def initialize
    current_path = File.expand_path File.dirname(__FILE__)
    @root_path = "#{current_path}/.."

    @speaker_info = {}
    @volume_threshold = 19
    @max_recent_log_msgs = 3

    logger = Syslog::Logger.new 'MonitorSonos'
    @logger = logger
    @recent_logs = []

    @track_volume_cache = {}
  end

  def run
    identify_speakers
  end

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

  def is_playing?(sp)
    if sp.now_playing.nil?
      false
    else
      artist = sp.now_playing[:artist]
      album = sp.now_playing[:album]

      track_duration = sp.now_playing[:track_duration]
      hours, minutes, seconds = track_duration.split(':').map { |i| i.to_i }
      total_seconds = hours*60*60 + minutes*60 + seconds

      playing = total_seconds > 0 or (artist.length > 0 and album.length > 0)

      if playing
        msg = "is playing but it is not playing: #{sp.ip}-#{sp.name}"
        log(msg, 'warn')
      end

      playing
    end
  end

  def monitor_speaker(sp)
    log("monitoring speaker: #{sp.ip}-#{sp.name}")

    while true
      @speaker_info[sp.ip] = {} if @speaker_info[sp.ip].nil?
      @speaker_info[sp.ip] = {name: sp.name, volume: sp.volume}

      if sp.now_playing.nil?
        @speaker_info[sp.ip][:playing] = nil
      elsif is_playing?(sp)
        @speaker_info[sp.ip][:playing] = {
            title: sp.now_playing[:title],
            track_duration: sp.now_playing[:track_duration],
            current_position: sp.now_playing[:current_position]
        }

        # save current music to playlist
        save_music(sp.now_playing)

        # only magic touch the volume if its playing
        update_volume(sp) if sp.volume.to_i > @volume_threshold
      end

      sleep 1
    end
  end

  def update_volume(sp)
    log("volume threshold reached: #{sp.ip}-#{sp.name}")
    track_duration = sp.now_playing[:track_duration]
    current_position = sp.now_playing[:current_position]

    track_hours, track_minutes, track_seconds = track_duration.split(':').map { |i| i.to_i }
    curr_hours, curr_minutes, curr_seconds = current_position.split(':').map { |i| i.to_i }

    track_total_seconds = track_hours*60*60 + track_minutes*60 + track_seconds
    current_second = curr_hours*60*60 + curr_minutes*60 + curr_seconds


    # if near the end of the music
    if (track_total_seconds - current_second).abs <= 20
      np = sp.now_playing
      item = {
          title: np[:title],
          artist: np[:artist],
          album: np[:album],
          track_duration: np[:track_duration]
      }

      item_key = Digest::MD5.hexdigest(item.to_json)

      # only lower the volume at least one time per music
      unless track_volume_cache.key?(item_key)
        unit = 1
        sp.volume = sp.volume.to_i-unit

        value = {
          timesamp: Time.now,
          total_track_seconds: track_total_seconds
         }

        track_volume_cache[item_key] = value
        log("volume lowered by #{unit} to #{sp.volume}: #{sp.ip}-#{sp.name}")
      end
    end
  end

  def update_track_volume_cache
    while true
      log("update_track_volume_cache.start: #{track_volume_cache.keys.length} total keys")
      track_volume_cache.each do |key, data|
        now = Time.now.to_i
        timestamp = data[:timestamp]
        total_track_seconds = data[:total_track_seconds]

        if now - timestamp >= track_total_seconds
          track_volume_cache.delete(key)
          log("track volume cache key deleted: #{key}")
        end
      end
      log("update_track_volume_cache.finish: #{track_volume_cache.keys.length} keys left")
      sleep 120
    end
  end

  def identify_speakers
    threads = []
    system = Sonos::System.new

    log('scanning for speakers')
    system.speakers.each do |sp|
      threads << Thread.new do
        monitor_speaker(sp)
      end
    end

    threads << Thread.new do
      display_info
    end

    threads << Thread.new do
      update_track_volume_cache
    end

    log('initialize threaded monitoring')
    threads.map(&:join)
  end

  def save_music(now_playing)
    playlist = "#{@root_path}/data/playlist.json"
    item = {
        title: now_playing[:title],
        artist: now_playing[:artist],
        album: now_playing[:album],
        track_duration: now_playing[:track_duration]
    }

    item_key = Digest::MD5.hexdigest(item.to_json)
    data = {}
    File.open(playlist, 'r') do |file|
      contents = file.read
      data = contents.empty? ? {} : JSON.parse(contents)
    end

    unless data.key?(item_key)
      data[item_key] = item
      File.open(playlist, 'w+') { |file| file.write(data.to_json) }
      git_commit("- #{now_playing[:title]} - #{now_playing[:artist]}")
      log('playlist updated')
    end
  end

  def save_volume(sp)
    datafile = "#{@root_path}/data/volume-history.json"
    item = {
        ip: sp.ip,
        name: sp.name,
        volume: sp.volume,
        timestamp: Time.now
    }

    item_key = Digest::MD5.hexdigest(item.to_json)
    data = {}
    File.open(datafile, 'r') do |file|
      contents = file.read
      data = contents.empty? ? {} : JSON.parse(contents)
    end

    unless data.key?(item_key)
      data[item_key] = item
      File.open(datafile, 'w+') { |file| file.write(data.to_json) }
      log('volume history updated')
    end
  end

  def git_commit(msg = '')
    `cd #{@root_path}/ && \
    git add . > /dev/null && \
    git commit -m "update playlist #{msg}"`

    if $?.exitstatus == 0
      log('git commit completed')
    else
      log($?.to_s, 'error')
    end

  end

  def log(msg, level = 'info')
    if level == 'info'
      @logger.info(msg)
    elsif level == 'error'
      @logger.error(msg)
    elsif level == 'warn'
      @logger.warn(msg)
    end

    max = @max_recent_log_msgs-1
    max = 0 if @max_recent_log_msgs < 0
    @recent_logs.unshift(msg)
    @recent_logs = @recent_logs[0 .. max]
  end
end
