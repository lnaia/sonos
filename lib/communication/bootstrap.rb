require 'socket'
require 'json'
require_relative 'handle_client'

module Communication
#:nodoc:
  class Bootstrap
    def initialize
      @default_port = 2001
    end

    def self.server(&block)
      new.send(:server, &block)
    end

    def self.client(&block)
      new.send(:client, &block)
    end

    def server
      @server = TCPServer.new @default_port
      loop do
        @client = @server.accept
        Process.fork do
          yield Communication::HandleClient.listen(@client)
        end
      end
    end

    def client
      @server = TCPSocket.new 'localhost', @default_port
      payload = read_payload
      content = content? payload

      while content
        puts payload
        yield payload
        payload = read_payload
        content = content? payload
      end

      @server.close
    end

    def content?(payload)
      !payload['content'].nil?
    end

    def read_payload
      data = @server.gets
      data.to_s.length.zero? ? empty_payload : JSON.parse(data)
    rescue JSON::ParserError
      empty_payload
    end

    def empty_payload
      { content: nil, error: true }
    end
  end
end
