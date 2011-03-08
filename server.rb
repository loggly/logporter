$: << File.join(File.dirname(__FILE__), "lib")
require "rubygems"
require "eventmachine"
require "logporter/server"
require "logporter/server/connection"

# Given a list of ports, listen on all of them
inputs = [
  LogPorter::Server.new(:port => 23424, :net => :tcp, :wire => :syslog),
  LogPorter::Server.new(:port => 23426, :net => :tcp, :wire => :raw),
  LogPorter::Server.new(:port => 23424, :net => :udp, :wire => :raw),
  LogPorter::Server.new(:port => 23425, :net => :tls, :wire => :raw),
  LogPorter::Server.new(:port => 23427, :net => :tls, :wire => :syslog),
]

EventMachine::run do
  inputs.each do |input|
    input.start
  end # inputs.each
end # EventMachine::run
