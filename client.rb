require_relative 'lib/communication/bootstrap'

def do_work(payload)
  puts "i just got this from the server: #{payload}"
end

Communication::Bootstrap.client do |payload|
  do_work(payload)
end
