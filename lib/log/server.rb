
module Log; end

class Log::Server
  TLSConfig = Struct.new :private_key_file, :cert_chain_file, :verify_peer

  attr_reader :tls
  attr_reader :port
  attr_reader :type
  attr_reader :protocol

  def initialize(type, options)
    @type = type
    @port = options.delete(:port) || 514
    @protocol = options.delete(:protocol) || :raw

    if @type == :tls
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
      puts "Starting #{@type}/#{@port}"
      case @type
        when :udp; start_udp_server
        when :tcp; start_tcp_server
        when :tls; start_tcp_server
      end
    end
  end # def start

  def start_udp_server
    EventMachine::open_datagram_socket "0.0.0.0", @port, Log::Server::Connection, self
  end # def start_udp

  def start_tcp_server
    EventMachine::start_server "0.0.0.0", @port, Log::Server::Connection, self
  end # def start_tcp
end
