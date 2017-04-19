require_relative 'communication'

Communication.server do |client|
  # client is connected
  loop do
    client << "this is me: #{Time.now.to_i}"
  end
end
