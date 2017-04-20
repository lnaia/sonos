require_relative 'lib/communication/client'

Communication::Client.run do |server|
  payload = server.gets
  while payload
    puts "server sent: #{payload}"
    server.puts 'This is client numero dos!'
  end
end
