require_relative '../config/boot'

# Require the gems listed in Gemfile, including any gems
Bundler.require
require_relative '../config/initializer'
require 'logger'
require 'fileutils'

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

  def self.speakers
    @speakers ||= {}
  end

  def self.monitor
    threads = []
    threads << MonitorSonos::Discovery.init
    threads << MonitorSonos::Display.init
    threads.map(&:join)
  end
end
