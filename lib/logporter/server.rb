require "logporter/namespace"
require "logporter/server/connection"
require "logporter/server/defaulthandler"
require "logger"

class LogPorter::Server

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

  # Arbitrary attributes for this server. You can store whatever you want here.
  # This is a hash
  attr_reader :attributes

  # The logger object
  attr_accessor :logger

  # Create a new server to listen with
  # 'options' is a hash of:
  #
  #   :net => the network layer to use (:udp, :tcp, :tls)
  #   :port => the port to listen on
  #   :wire => the wire format (:raw, :syslog)
  #   :handler => the handler instance. Must respond to 'receive_event'
  def initialize(options)
    @logger = Logger.new(STDOUT)
    @network = options[:net]
    @port = options.delete(:port) || 514
    @wire = options.delete(:wire) || :raw
    @handler = options.delete(:handler) || LogPorter::Server::DefaultHandler.new
    @attributes = options.delete(:attributes) || Hash.new

    if @network == :tls
      @tls = TLSConfig.new
      @tls.private_key_file = options[:private_key]
      @tls.cert_chain_file = options[:certificate_chain]
      @tls.verify_peer = options[:verify_peer] || false
    else
      @tls = nil
    end
  end # def initialize

  # start the server
  public
  def start
    # We use next_tick here in case you are invoking this method from outside
    # of EventMachine; this allows you to do this:
    #
    #   s = LogPorter::server.new ...
    #   s.start
    #
    #   EventMachine.run()
    if EventMachine.reactor_running?
      _start
    else
      EventMachine.next_tick { _start }
    end
  end # def start

  private
  def _start
    @logger.info "Starting #{@network}/#{@port}"
    begin
      case @network
        when :udp; start_udp_server
        when :tcp; start_tcp_server
        when :tls; start_tcp_server # tls is handled by tcp.
        else
          raise "Unknown network '#{@network}' expected :udp, :tcp, or :tls"
      end
    rescue => e
      if @handler.respond_to?(:receive_exception)
        @handler.receive_exception(e, self)
      else
        raise e
      end
    end
  end # def _start

  private
  def start_udp_server
    @socket = EventMachine::open_datagram_socket "0.0.0.0", @port,
      LogPorter::Server::Connection, self
  end # def start_udp

  private
  def start_tcp_server
    @socket = EventMachine::start_server "0.0.0.0", @port,
      LogPorter::Server::Connection, self
  end # def start_tcp

  # This method is invoked by LogPorter::Server::Connection
  public
  def receive_event(event, client_addr, client_port)
    @handler.receive_event(event, self, client_addr, client_port)
  end # def receive_event

  public
  def stop
    @logger.info "Stopping #{@network}/#{@port}"
    case @network
      when :tcp
        EventMachine::stop_server(@socket)
      when :tls
        EventMachine::stop_server(@socket)
      when :udp
        @socket.close_connection(true)
    end
  end # def stop
end # class LogPorter::Server
