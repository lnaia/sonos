require_relative '../config/boot'

# Require the gems listed in Gemfile, including any gems
Bundler.require
require_relative '../config/initializer'
require 'logger'
require 'fileutils'
require 'json'

# :nodoc:
module MonitorSonos
  def self.root
    "#{File.expand_path File.dirname(__FILE__)}/.."
  end

  def self.config
    YAML.load_file("#{root}/config/defaults.yml")
  end

  def self.logger
    logfile = "#{root}/logs/application.log"
    FileUtils.touch logfile unless File.exist? logfile
    @logger ||= Logger.new(logfile, 'weekly').tap do |l|
      l.progname = 'MonitorSonos'
      l.level = Logger::INFO
      l.formatter = proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime '%Y-%m-%d %H:%M:%S '
        "[#{date_format}] #{severity} (#{progname}): #{msg}\n"
      end
    end
  end

  def self.speakers(uid: nil)
    if uid.nil?
      redis.hgetall('h_speakers')
    else
      redis.hget('h_speakers', uid)
    end
  end

  def self.save_speaker(key, data)
    redis.hmset('h_speakers', [key, data.to_json])
  end

  def self.subscribe(*args)
    redis.subscribe(*args)
  end

  def self.publish(data)
    Redis.new.publish 'c_speakers', data.to_json
  end

  def self.redis
    @redis ||= Redis.new
  end
end
