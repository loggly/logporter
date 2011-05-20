$: << File.join(File.dirname(__FILE__), "lib")
require "rubygems"
require "eventmachine"
require "logporter/server"
require "logporter/server/connection"

class Handler
  def initialize
    @count = 0
    @start = Time.now
  end
  def receive_event(event, server, address, port)
    @count += 1

    if @count % 10000 == 0
      puts @count / (Time.now - @start)
      @count = 0
      @start = Time.now
    end
  end # def receive_event
end # class Handler

EventMachine::run do
  input = LogPorter::Server.new(:port => 23424, :net => :udp,
                                :wire => :syslog_no_parse_time,
                                :handler => Handler.new)
  input.start
end # EventMachine::run
