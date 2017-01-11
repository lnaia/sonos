require 'sonos'

class Monitor
  attr_reader :speaker_info

  def initialize(logger, volume_threshold = 18)
    @volume_threshold = volume_threshold
    @logger = logger

    @track_volume_cache = {}
    @speaker_info = {}
  end

  def prepare_threads
    threads = []
    sonos = Sonos::System.new
    @logger.log('scanning for speakers')

    sonos.speakers.each do |sp|
      threads << Thread.new { monitor_speaker(sp) }
    end

    threads << Thread.new { update_track_volume_cache }
    threads
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
        msg = "says it is playing but it is not: #{sp.ip}-#{sp.name}"
        @logger.log(msg, 'warn')
      end

      playing
    end
  end

  def monitor_speaker(sp)
    @logger.log("monitoring speaker: #{sp.ip}-#{sp.name}")

    while true
      @speaker_info[sp.ip] = {} if @speaker_info[sp.ip].nil?
      @speaker_info[sp.ip] = {name: sp.name, volume: sp.volume}

      if sp.now_playing.nil?
        @speaker_info[sp.ip][:playing] = nil
      elsif is_playing?(sp)
        @speaker_info[sp.ip][:playing] = sp.now_playing

        # only magic touch the volume if its playing
        update_volume(sp) if sp.volume.to_i > @volume_threshold
      end

      sleep 1
    end
  end

  def update_volume(sp)
    @logger.log("volume threshold reached: #{sp.ip}-#{sp.name}")
    track_duration = sp.now_playing[:track_duration]
    current_position = sp.now_playing[:current_position]

    track_hours, track_minutes, track_seconds = track_duration.split(':').map { |i| i.to_i }
    curr_hours, curr_minutes, curr_seconds = current_position.split(':').map { |i| i.to_i }

    track_total_seconds = track_hours*60*60 + track_minutes*60 + track_seconds
    current_second = curr_hours*60*60 + curr_minutes*60 + curr_seconds


    # if near the end of the music
    if (track_total_seconds - current_second).abs <= 20
      require 'digest/md5'
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
        @logger.log("volume lowered by #{unit} to #{sp.volume}: #{sp.ip}-#{sp.name}")
      end
    end
  end

  def update_track_volume_cache
    while true
      msg = "volume cache start: #{track_volume_cache.keys.length} total keys"
      @logger.log(msg)

      track_volume_cache.each do |key, data|
        now = Time.now.to_i
        timestamp = data[:timestamp]
        total_track_seconds = data[:total_track_seconds]

        if now - timestamp >= track_total_seconds
          track_volume_cache.delete(key)
          @logger.log("track volume cache key deleted: #{key}")
        end
      end

      msg = "volume cache finish: #{track_volume_cache.keys.length} keys left"
      @logger.log(msg)
      sleep 120
    end
  end
end
