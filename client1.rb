require_relative 'lib/communication/client'

Communication::Client.run do |server|
  server.puts 'this is client one A'
  server.puts 'this is client one B'
  loop do
    server.puts "the time is: #{Time.now.to_i}"
    sleep 1
  end
end
