require_relative 'boot'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require
require_relative 'initializer'
require 'logger'
require 'fileutils'

module MonitorSonos
  def self.join(*args)
    args.each { |i| threads << i }
    threads.map(&:join)
  end

  def self.root
    "#{File.expand_path File.dirname(__FILE__)}/.."
  end

  def self.config
    YAML.load_file("#{root}/config/defaults.yml")
  end

  def self.logger
    @logs ||= []
    logfile = "#{root}/logs/application.log"
    FileUtils.touch logfile unless File.exist? logfile
    @logger ||= Logger.new(logfile).tap do |l|
      l.progname = 'MonitorSonos'
      l.level = Logger::DEBUG
      l.formatter = proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime '%Y-%m-%d %H:%M:%S '
        "[#{date_format}] #{severity} (#{progname}): #{msg}\n".tap do |message|
          add_log message.strip
        end
      end
    end
  end

  def self.add_log(msg)
    max = 5
    @logs.unshift msg
    @logs = @logs.slice(0, max)
  end

  def self.<<(items)
    _threads = threads
    if items.kind_of? Array
      _threads+= items
    else
      _threads << items
    end
    _threads
  end

  def self.logs
    @logs
  end

  def self.speakers
    @speakers ||= {}
  end

  def self.threads
    @threads ||= []
  end
end