require 'assert'
require 'logsly/syslog_output'

class Logsly::SyslogOutput

  class BaseTests < Assert::Context
    desc "the SyslogOutput handler"
    setup do
      @out = Logsly::SyslogOutput.new {}
    end
    subject { @out }

    should "be an output handler" do
      assert_kind_of Logsly::BaseOutput, subject
    end

    should "build a syslog Logging appender"
  end

end

