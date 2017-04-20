require 'socket'

module Communication
#:nodoc:
  class Server
    def initialize
      @default_port = 2001
      @clients = Queue.new
    end

    def self.run(&block)
      new.send(:run, &block)
    end

    def run
      server = TCPServer.new @default_port
      loop do
        client = server.accept
        logger 'client connected'
        @clients << client
        Thread.new { listen(client) }.join()
      end
    end

    def listen(client)
      payload = client.gets.strip
      content = !payload.nil?
      logger "server got client message [#{payload}]"
      broadcast(payload) while content
    rescue => ex
      logger "client disconnected #{ex.message}"
      @clients.delete client
      puts "fork clients: #{@clients}"
      client.close
      exit 1
    end

    def broadcast(payload)
      @clients.each { |client| client.puts payload }
    end

    def logger(msg)
      puts msg
    end

  end
end
