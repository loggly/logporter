
require "test/unit"
require "logporter/protocol/syslog3164"
require "logporter/event"

class TestSyslog3164Parser < Test::Unit::TestCase
  include LogPorter::Protocol::Syslog3164

  def test_full_valid_message
    messages = {
      "<12>Mar  1 15:43:35 snack kernel: Kernel logging (proc) stopped." => {
        :pri => "12",
        :timestamp => "Mar  1 15:43:35",
        :hostname => "snack",
        :message => "kernel: Kernel logging (proc) stopped."
      },
      "<1>Jun 17 03:29:44 1.2.3.4 fancypants" => {
        :pri => "1",
        :timestamp => "Jun 17 03:29:44",
        :hostname => "1.2.3.4",
        :message => "fancypants"
      },
      "<100>Dec 31 22:00:00 ffe0::1 something[12345]: hello world" => {
        :pri => "100",
        :timestamp => "Dec 31 22:00:00",
        :hostname => "ffe0::1",
        :message => "something[12345]: hello world",
      },
    }

    event = LogPorter::Event.new
    messages.each do |input, expect|
      assert(parse_rfc3164(input, event), "Parse should return true on a valid message")

      expect.each do |key, value|
        actual = event.send(key.to_sym) # invoke 'event.message' or whatever 'key' is
        assert_equal(value, actual, "Expected event.#{key} == #{value.inspect}, got #{actual.inspect}")
      end
    end
  end # def test_full_valid_message

  def test_valid_message_no_pri
    messages = {
      "Mar  1 15:43:35 snack kernel: Kernel logging (proc) stopped." => {
        :pri => "13",
        :timestamp => "Mar  1 15:43:35",
        :hostname => "snack",
        :message => "kernel: Kernel logging (proc) stopped."
      },
      "Jun 17 03:29:44 1.2.3.4 fancypants" => {
        :pri => "13",
        :timestamp => "Jun 17 03:29:44",
        :hostname => "1.2.3.4",
        :message => "fancypants"
      },
      "Dec 31 22:00:00 ffe0::1 something[12345]: hello world" => {
        :pri => "13",
        :timestamp => "Dec 31 22:00:00",
        :hostname => "ffe0::1",
        :message => "something[12345]: hello world",
      },
    }

    event = LogPorter::Event.new
    messages.each do |input, expect|
      assert(parse_rfc3164(input, event), "Parse should return true on a valid message")

      expect.each do |key, value|
        actual = event.send(key.to_sym) # invoke 'event.message' or whatever 'key' is
        assert_equal(value, actual, "Expected event.#{key} == #{value.inspect}, got #{actual.inspect}")
      end
    end
  end # def test_valid_message_no_pri

  def test_invalid_message
    messages = [
      " Mar  1 15:43:35 snack kernel: Kernel logging (proc) stopped.",
      "<1234>Jun 17 03:29:44 1.2.3.4 fancypants",
      "<123>Mon, Dec 31 22:00:00 ffe0::1 something[12345]: hello world",
    ]

    event = LogPorter::Event.new
    messages.each do |input|
      assert(parse_rfc3164(input, event) == false, "Parse should return false on a invalid message #{input.inspect}")
    end
  end # def test_invalid_message
end # class TestSyslog3164Parser
