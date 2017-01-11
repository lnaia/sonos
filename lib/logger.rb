class Logger
  attr_reader :logger
  attr_reader :recent_logs

  def initialize(max_recent_log_msgs = 3)
    @logger = Syslog::Logger.new 'MonitorSonos'
    @recent_logs = []
    @max_recent_log_msgs = 3
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
