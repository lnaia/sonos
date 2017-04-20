require_relative 'lib/communication/bootstrap'
require_relative 'lib/communication/bootstrap'

def start_server
  spawn('ruby server.rb').tap do |pid|
    Process.detach(pid)
    start_client(pid)
  end
end

def start_client(server_pid)
  puts 'start client'
  keep_trying = true
  while keep_trying
    begin
      puts 'trying to connect...'
      Communication::Bootstrap.client do |payload|
        puts "i just got this from the server: #{payload}"
      end
    rescue Errno::ECONNREFUSED
      puts 'Connection refusing, trying again....'
    rescue
      keep_trying = false
    end
    sleep 1
  end
ensure
  Process.kill(9, server_pid)
end

start_server
