require "log/namespace"
require "eventmachine"
require "log/protocol/syslog3164"
require "log/event"
require "socket"

class Log::Server::Connection < EventMachine::Connection
  #include EventMachine::Protocols::LineText2
  #include EventMachine::Protocols::LineAndTextProtocol
  #include EventMachine::Protocols::LineProtocol
  include Log::Protocol::Syslog3164
 
  def initialize(server)
    @server = server
  end

  def post_init
    super

    if @server.type == :tls
      if RUBY_PLATFORM == "java"
        raise "EventMachine doesn't support TLS on JRuby :("
      end

      start_tls(
        :private_key_file => @server.tls.private_key_file,
        :cert_chain_file => @server.tls.cert_chain_file,
        :verify_peer => @server.tls.verify_peer
      )
    end
    
    @count = 0

    case @server.protocol
    when :raw
      class << self
        alias_method :receive_line, :receive_line_raw
      end
    when :syslog
      class << self
        alias_method :receive_line, :receive_line_syslog
      end
    else
      #raise "Unsupported protocol #{@server.protocol}"
    end

    begin
      @client_port, @client_address = Socket.unpack_sockaddr_in(get_peername)
      puts "New client: #{@client_address}:#{@client_port}"
    rescue => e
      p e
    end
  end # def post_init

  #def ssl_handshake_completed
    # TODO(sissel): validate other pieces of the cert?
    #puts get_peer_cert
  #end

  def receive_data(data)
    @buffer ||= BufferedTokenizer.new
    @buffer.extract(data).each do |line|
      receive_line(line.chomp)
    end
  end

  def _receive_line(line)
    receive_line_raw(line)
  end

  def receive_line_raw(line)
    #event = Log::Event.new

    # RFC3164 section 4.3.3 No PRI or Unidentifiable PRI
    #event.pri = "13"  

    # TODO(sissel): Look for an alternative to Time#strftime since it is
    # insanely slow.
    #event.timestamp = Time.now.strftime("%b %d %H:%M:%S")
    #event.timestamp = Time.now
    #event.hostname = @client_address
    #event.message = line

    stats
    #puts event
  end

  def stats
    @start ||= Time.now
    @count += 1
    if @count % 50000 == 0
      puts "Rate: #{@count / (Time.now - @start)}"
      @start = Time.now
      @count = 0
    end
  end

  def receive_line_syslog(line)
    if @client_address == nil
      @client_port, @client_address = Socket.unpack_sockaddr_in(get_peername)
      puts "New client: #{@client_address}:#{@client_port}"
    end

    event = Log::Event.new
    if parse_rfc3164(line, event)
    #elsif parse_rfc5424(line, event)
    else 
      port, address = Socket.unpack_sockaddr_in(get_peername)

      # RFC3164 section 4.3.3 No PRI or Unidentifiable PRI
      event.pri = "13"  
      event.timestamp = Time.now
      event.hostname = address
      event.message = line
    end

    #puts event
    stats
  end # def receive_syslog
end
