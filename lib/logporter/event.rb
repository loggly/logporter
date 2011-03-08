require "logporter/namespace"

class LogPorter::Event
  attr_accessor :pri
  attr_accessor :timestamp
  attr_accessor :hostname
  attr_accessor :message
  attr_accessor :raw

  def to_s
    if @raw == true
      return message
    else
      return "<#{pri}>#{timestamp} #{hostname} #{message}"
    end
  end
end
