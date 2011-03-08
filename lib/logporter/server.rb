require "log/namespace"
require "log/server/defaulthandler"

module Log; end

class Log::Server

  # Create a new class called 'TLSConfig' which simply acts as a data structure.
  TLSConfig = Struct.new :private_key_file, :cert_chain_file, :verify_peer

  # The port we are listening on
  attr_reader :port

  # TLS options, only meaningful if @network == :tls
  attr_reader :tls

  # The network layer, :tcp, :udp, or :tls
  attr_reader :network

  # The wire format (syslog, raw, etc)
  attr_reader :wire

  def initialize(options)
    @network = options[:net]
    @port = options.delete(:port) || 514
    @wire = options.delete(:wire) || :raw
    @handler = options.delete(:handler) || Log::Server::DefaultHandler.new

    if @network == :tls
      @tls = TLSConfig.new
      @tls.private_key_file = options[:private_key]
      @tls.cert_chain_file = options[:certificate_chain]
      @tls.verify_peer = options[:verify_peer] || false
    else
      @tls = nil
    end
  end

  def start
    EventMachine.next_tick do
      puts "Starting #{@network}/#{@port}"
      case @network
        when :udp; start_udp_server
        when :tcp; start_tcp_server
        when :tls; start_tcp_server
        else
          raise "Unknown network '#{@network}' expected :udp, :tcp, or :tls"
      end
    end
  end # def start

  def start_udp_server
    EventMachine::open_datagram_socket "0.0.0.0", @port, Log::Server::Connection, self
  end # def start_udp

  def start_tcp_server
    EventMachine::start_server "0.0.0.0", @port, Log::Server::Connection, self
  end # def start_tcp

  def receive_event(event, client_addr, client_port)
    @handler.receive_event(event, self, client_addr, client_port)
  end
end
