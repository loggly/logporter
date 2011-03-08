require "logporter/namespace"

class LogPorter::Event
  attr_accessor :pri
  attr_accessor :timestamp
  attr_accessor :hostname
  attr_accessor :message
  attr_accessor :raw

  # TODO(sissel): Should we include other source information like client
  # address and port?

  def time_iso8601
    return timestamp.strftime("%Y-%m-%dT%H:%M:%S.") + timestamp.tv_usec.to_s
  end

  def to_s
    if @raw == true
      return message
    else
      return "<#{pri}>#{time_iso8601} #{hostname} #{message}"
    end
  end
end
