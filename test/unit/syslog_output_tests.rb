require 'assert'
require 'logsly/syslog_output'

require 'ostruct'
require 'syslog'
require 'logging'
require 'logsly'

class Logsly::SyslogOutput

  class UnitTests < Assert::Context
    desc "Logsly::SyslogOutput"
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
    subject{ @out }

    should "be an output handler" do
      assert_kind_of Logsly::BaseOutput, subject
    end

    should "build a Logging syslog appender, passing args to the builds" do
      appender = subject.to_appender @logger

      assert_kind_of Logging::Appenders::Syslog, appender
      assert_kind_of Logging::Layouts::Pattern,  appender.layout
      assert_equal   '%d : %m\n',                appender.layout.pattern
      assert_kind_of Logging::ColorScheme,       appender.layout.color_scheme
    end

  end

  class SyslogOutputDataTests < Assert::Context
    desc "SyslogOutputData"
    setup do
      @data = Logsly::SyslogOutputData.new {}
    end
    subject{ @data }

    should have_imeth :identity, :log_opts, :facility

    should "default :log_opts" do
      assert_equal (Syslog::LOG_PID | Syslog::LOG_CONS), subject.log_opts
    end

    should "default :facility" do
      assert_equal Syslog::LOG_LOCAL0, subject.facility
    end

  end

end
