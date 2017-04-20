require_relative 'lib/communication/bootstrap'

Communication::Bootstrap.server do |client|
  # client is connected
  loop do
    msg = "this is me: #{Time.now.to_i}"
    puts "server msg: [#{msg}]"
    client << msg
  end
end
