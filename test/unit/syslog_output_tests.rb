require 'assert'
require 'ostruct'
require 'syslog'
require 'logging'
require 'logsly/syslog_output'

class Logsly::SyslogOutput

  class BaseTests < Assert::Context
    desc "the SyslogOutput handler"
    setup do
      @logger = OpenStruct.new
      @logger.debug_level = :white
      @logger.pattern  = '%d : %m\n'
      @logger.identity = "whatever"
      @logger.facility = Syslog::LOG_LOCAL3

      Logsly.colors('a_color_scheme') do |logger|
        debug logger.debug_level
      end

      @out = Logsly::SyslogOutput.new do |logger|
        identity logger.identity
        facility logger.facility

        pattern logger.pattern
        colors  'a_color_scheme'
      end
    end
    subject { @out }

    should have_imeth :identity, :log_opts, :facility

    should "be an output handler" do
      assert_kind_of Logsly::BaseOutput, subject
    end

    should "default :log_opts" do
      assert_equal (Syslog::LOG_PID | Syslog::LOG_CONS), subject.log_opts
    end

    should "default :facility" do
      assert_equal Syslog::LOG_LOCAL0, subject.facility
    end

    should "build a Logging syslog appender, passing args to the builds" do
      subject.run_build @logger

      assert_kind_of Logging::Appenders::Syslog, subject.to_appender
      assert_kind_of Logging::Layouts::Pattern, subject.to_appender.layout
      assert_equal   '%d : %m\n', subject.to_appender.layout.pattern
      assert_kind_of Logging::ColorScheme, subject.to_appender.layout.color_scheme
    end
  end

end
