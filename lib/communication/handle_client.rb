require 'json'

module Communication
#:nodoc:
  class HandleClient
    def self.listen(client)
      @client = client
      self
    end

    def self.<<(payload)
      data = { content: payload }
      @client.puts data.to_json
    rescue => ex
      puts "#{ex.message} - client d/c ?"
      exit 1
      @client.close
    end
  end
end
