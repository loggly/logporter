require "logporter/namespace"

# Ruby's core/stdlib Time.strptime is embarrasingly slow.
# Let's do our own.
class TimeParser
  @@re_cache = {}
  @@re_formats = {
    "%b" => "(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)",
    "%d" => "[ 1-3]?[0-9]",
    "%H" => "[0-9]{2}",
    "%M" => "[0-9]{2}",
    "%S" => "[0-9]{2}",
  }

  def self.strptime(string, format)
    if @@re_cache.include?(format)
      obj = @@re_cache[format]
    else
      captures = []
      pattern = format.gsub(/%[A-z]/) do |spec|
        if @@re_formats.include?(spec)
          captures << spec
          "(#{@@re_formats[spec]})"
        else
          spec
        end
      end
      re = Regexp.new(pattern)
      obj = @@re_cache[format] = {
        :re => re,
        :captures => captures,
      }
    end

    #m = obj[:re].match(string)
    #return nil if !m

    now = Time.new
    time_array = [now.year, now.month, now.day, 0, 0, 0, 0]
    return nil unless string.scan(obj[:re]) do |*captures|
      #obj[:captures].each_with_index do |spec, i|
        #p spec => m[i + 1]
      captures.each_with_index do |spec, i|
        case spec
          when "%y"; time_array[0] = m[i + 1].to_i
          when "%b"; time_array[1] = m[i + 1]
          when "%d"; time_array[2] = m[i + 1].to_i
          when "%H"; time_array[3] = m[i + 1].to_i
          when "%M"; time_array[4] = m[i + 1].to_i
          when "%S"; time_array[5] = m[i + 1].to_i
        end # case spec
      end # each capture
    end # string.scan

    return Time.local(*time_array)
  end # def strptime
end # class TimeParser

module LogPorter::Protocol::Syslog3164
  def syslog3164_init
    pri = "(?:<(?<pri>[0-9]{1,3})>)?"
    month = "(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
    day = "(?: [1-9]|[12][0-9]|3[01])"
    hour = "(?:[01][0-9]|2[0-4])"
    minute = "(?:[0-5][0-9])"
    second = "(?:[0-5][0-9])"

    #pri = "(?:<(?<pri>[0-9]{1,3})>)?"
    #month = "(?:[A-z]{3})"
    #day = "[ 1-9][0-9]"
    #hour = "[0-9]{2}"
    #minute = "[0-9]{2}"
    #second = "[0-9]{2}"

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

  def parse_rfc3164(line, event, opts)
    syslog3164_init if !@syslog3164_re
    m = @syslog3164_re.match(line)
    if m
      # RFC3164 section 4.3.3 No PRI or Unidentifiable PRI
      event.pri = m[1] || "13"

      if opts[:parse_time] 
        event.timestamp = TimeParser.strptime(m[2], "%b %d %H:%M:%S")
      else
        event.timestamp = Time.now
      end
      event.hostname = m[3]
      event.message = m[4]
      return true
    end
    return false
  end # def parse_rfc3164
end # module Log::Protocol::Syslog3164

