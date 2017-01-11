
class DataOperations
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
end
