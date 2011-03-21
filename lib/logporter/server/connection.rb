require "eventmachine"
require "logporter/event"
require "logporter/namespace"
require "logporter/protocol/syslog3164"
require "logporter/server"
require "socket"

class LogPorter::Server::Connection < EventMachine::Connection
  include LogPorter::Protocol::Syslog3164
 
  def initialize(server)
    @server = server
  end

  def post_init
    super

    if @server.network == :tls
      if RUBY_PLATFORM == "java"
        $STDERR.puts "Warning... EventMachine doesn't support TLS on JRuby :("
      end

      # Calls EventMachine::Connection#start_tls
      start_tls(
        :private_key_file => @server.tls.private_key_file,
        :cert_chain_file => @server.tls.cert_chain_file,
        :verify_peer => @server.tls.verify_peer
      )
    end
    
    @count = 0

    case @server.wire
      when :raw
        class << self
          alias_method :receive_line, :receive_line_raw
        end
      when :syslog
        class << self
          alias_method :receive_line, :receive_line_syslog
        end
      else
        raise "Unsupported protocol #{@server.protocol}"
    end

    begin
      @client_port, @client_address = Socket.unpack_sockaddr_in(get_peername)
      @server.logger.info "New client: #{@client_address}:#{@client_port}"
    rescue => e
      p e
    end
  end # def post_init

  #def ssl_handshake_completed
    # TODO(sissel): validate other pieces of the cert?
    #puts get_peer_cert
  #end

  def receive_data(data)
    if @server.network == :udp
      client_port, client_address = Socket.unpack_sockaddr_in(get_peername)
    else
      client_port = @client_port
      client_address = @client_address
    end

    @buffer ||= BufferedTokenizer.new
    @buffer.extract(data).each do |line|
      receive_line(line.chomp, client_address, client_port)
    end
  end

  def receive_line_raw(line, address, port)
    event = LogPorter::Event.new

    # TODO(sissel): Look for an alternative to Time#strftime since it is
    # insanely slow.
    event.pri = "13" # RFC3164 says unknown pri == 13.
    event.timestamp = Time.now
    event.hostname = address
    event.message = line
    event.raw = true

    @server.receive_event(event, address, port)
    stats
  end

  def receive_line_syslog(line, address, port)
    event = LogPorter::Event.new
    if parse_rfc3164(line, event)
    #elsif parse_rfc5424(line, event)
    else 
      # Unknown message format, add syslog headers.
      event.pri = "13" # RFC3164 says unknown pri == 13.
      event.timestamp = Time.now
      event.hostname = address
      event.message = line
    end

    @server.receive_event(event, address, port)
    stats
  end # def receive_line_syslog

  def stats
    @start ||= Time.now
    @count += 1
    if (Time.now - @start) > 10
      @server.logger.info "Rate: #{@count / (Time.now - @start)}"
      @start = Time.now
      @count = 0
    end
  end # def stats
end
