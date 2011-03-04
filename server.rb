require "rubygems"
require "eventmachine"
require "log/server"
require "log/server/connection"

# Given a list of ports, listen on all of them
inputs = [
  Log::Server.new(:port => 23424, :net => :tcp, :wire => :syslog),
  Log::Server.new(:port => 23426, :net => :tcp, :wire => :raw),
  Log::Server.new(:port => 23424, :net => :udp, :wire => :raw),
  Log::Server.new(:port => 23425, :net => :tls, :wire => :raw),
]

EventMachine::run do
  inputs.each do |input|
    input.start
  end # inputs.each
end # EventMachine::run
