require 'socket'

module Communication
#:nodoc:
  class Client
    def initialize
      @default_port = 2001
      @clients = []
    end

    def self.run(&block)
      new.send(:run, &block)
    end

    def run
      @server = TCPSocket.new 'localhost', @default_port
      yield @server
    ensure
      @server.close
    end
  end
end
