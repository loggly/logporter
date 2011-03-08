require "logporter/namespace"

module LogPorter::Protocol::Syslog3164
  def syslog3164_init
    pri = "(?:<(?<pri>[0-9]{1,3})>)?"
    month = "(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
    day = "(?: [1-9]|[12][0-9]|3[01])"
    hour = "(?:[01][0-9]|2[0-4])"
    minute = "(?:[0-5][0-9])"
    second = "(?:[0-5][0-9])"

    time = [hour, minute, second].join(":")

    timestamp = "(?<timestamp>#{month} #{day} #{time})"
    hostname = "(?<hostname>[A-Za-z0-9_.:]+)"
    header = timestamp + " " + hostname
    message = "(?<message>[ -~]+)"  # ascii 32 to 126
    re = "^#{pri}#{header} #{message}$"

    if RUBY_VERSION =~ /^1\.8/
      # Ruby 1.8 doesn't support named captures
      # replace (?<foo> with (
      re = re.gsub(/\(\?<[^>]+>/, "(")
    end

    @syslog3164_re = Regexp.new(re)
  end

  def parse_rfc3164(line, event)
    syslog3164_init if !@syslog3164_re
    m = @syslog3164_re.match(line)
    if m
      # RFC3164 section 4.3.3 No PRI or Unidentifiable PRI
      event.pri = m[1] || "13"
      event.timestamp = m[2]
      event.hostname = m[3]
      event.message = m[4]
      return true
    end
    return false
  end # def parse_rfc3164
end # module Log::Protocol::Syslog3164

