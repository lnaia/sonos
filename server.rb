require_relative 'lib/communication/bootstrap'

Communication::Bootstrap.server do |client|
  # client is connected
  loop do
    client << "this is me: #{Time.now.to_i}"
  end
end
