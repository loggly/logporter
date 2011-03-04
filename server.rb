require "rubygems"
require "eventmachine"
require "log/server"
require "log/server/connection"

# Given a list of ports, listen on all of them
inputs = [
  Log::Server.new(:tcp, :port => 23424),
  Log::Server.new(:udp, :port => 23424),
  Log::Server.new(:tls, :port => 23425),
]

EventMachine::run do
  inputs.each do |input|
    input.start
  end # inputs.each
end # EventMachine::run
