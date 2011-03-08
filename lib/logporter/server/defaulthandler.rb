

require "logporter/namespace"

class LogPorter::Server::DefaultHandler 
  def receive_event(event, server, client_addr, client_port)
    puts "#{client_addr}:#{client_port}(#{server.network}/#{server.wire}) => #{event}"
  end # def receive_event
end # class Log::Server::DefaultHandler 
