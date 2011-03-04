require "log/namespace"

class Log::Event
  attr_accessor :pri
  attr_accessor :timestamp
  attr_accessor :hostname
  attr_accessor :message

  def to_s
    return "<#{pri}>#{timestamp} #{hostname} #{message}"
  end
end
