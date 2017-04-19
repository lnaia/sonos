require_relative 'communication'

def do_work(payload)
  puts "i just got this from the server: #{payload}"
end

Communication.client do |payload|
  do_work(payload)
end
