require 'assert'
require 'logsly/outputs'

require 'logsly/logging182'
require 'logsly'

module Logsly::Outputs

  class UnitTests < Assert::Context
    desc "Logsly::Outputs"

  end

  class BaseTests < UnitTests
    desc "Base"
    setup do
      @out = Base.new
    end
    subject{ @out }

    should have_reader :build
    should have_imeths :to_layout, :to_appender

    should "know its build" do
      build_proc = Proc.new{}
      out = Base.new(&build_proc)

      assert_same build_proc, out.build
    end

    should "expect `to_appender` to be defined by subclasses" do
      assert_raises NotImplementedError do
        subject.to_appender
      end
    end

  end

  class BaseBuildTests < BaseTests
    desc "given a build"
    setup do
      Logsly.colors('a_color_scheme') do
        debug_line :white
      end
      @out = Base.new do |*args|
        pattern args.first
        colors  'a_color_scheme'
      end
    end

    should "build a Logsly::Logging182 pattern layout" do
      data = BaseData.new('[%c{2}] [%l] %d : %m : %X{test} : %x :\n', &@out.build)
      lay = subject.to_layout(data)

      assert_kind_of Logsly::Logging182::Layout, lay
      assert_kind_of Logsly::Logging182::ColorScheme, lay.color_scheme
      assert_equal '[%c{2}] [%l] %d : %m : %X{test} : %x :\n', lay.pattern

      assert_nothing_raised do
        event = ::Logsly::Logging182::LogEvent.new(
          Factory.string,
          ::Logsly::Logging182::LEVELS['debug'],
          {},
          []
        )
        lay.format(event)
      end
    end

  end

  class BaseDataTests < UnitTests
    desc "BaseData"
    setup do
      Logsly.colors('a_color_scheme') do
        debug :white
      end
      @arg = '%d : %m\n'
      @data = BaseData.new(@arg) do |*args|
        pattern args.first
        colors  'a_color_scheme'
      end
    end
    subject{ @data }

    should have_imeths :pattern, :colors

    should "know its defaults" do
      data = BaseData.new
      assert_equal '%m\n', data.pattern
      assert_nil data.colors
    end

    should "instance exec its build with args" do
      assert_equal '%d : %m\n',      subject.pattern
      assert_equal 'a_color_scheme', subject.colors
    end

    should "know its layout pattern opts hash" do
      exp = {
        :pattern      => subject.pattern,
        :color_scheme => "#{subject.colors}-#{@arg.object_id}"
      }
      assert_equal exp, subject.to_pattern_opts

      data = BaseData.new{ pattern '%m\n'  }
      exp = { :pattern => data.pattern }
      assert_equal exp, data.to_pattern_opts
    end

  end

  class StdoutTests < UnitTests
    desc "Stdout"
    setup do
      @logger = OpenStruct.new
      @logger.debug_level = :white
      @logger.pattern = '%d : %m\n'

      Logsly.colors('a_color_scheme') do |logger|
        debug logger.debug_level
      end

      @out = Stdout.new do |logger|
        pattern logger.pattern
        colors  'a_color_scheme'
      end
    end
    subject{ @out }

    should "be a Base output" do
      assert_kind_of Base, subject
    end

    should "build a Logsly::Logging182 stdout appender, passing args to the builds" do
      appender = subject.to_appender @logger

      assert_kind_of Logsly::Logging182::Appenders::Stdout, appender
      assert_kind_of Logsly::Logging182::Layouts::Pattern,  appender.layout
      assert_kind_of Logsly::Logging182::ColorScheme,       appender.layout.color_scheme
      assert_equal '%d : %m\n', appender.layout.pattern
    end

  end

  class FileTests < UnitTests
    desc "File"
    setup do
      @logger = OpenStruct.new
      @logger.debug_level = :white
      @logger.pattern = '%d : %m\n'
      @logger.file = "log/dev.log"

      Logsly.colors('a_color_scheme') do |logger|
        debug logger.debug_level
      end

      @out = File.new do |logger|
        path logger.file

        pattern logger.pattern
        colors  'a_color_scheme'
      end
    end
    subject{ @out }

    should "be a Base output" do
      assert_kind_of Base, subject
    end

    should "build a Logsly::Logging182 file appender, passing args to the builds" do
      appender = subject.to_appender @logger

      assert_kind_of Logsly::Logging182::Appenders::File,  appender
      assert_kind_of Logsly::Logging182::Layouts::Pattern, appender.layout
      assert_kind_of Logsly::Logging182::ColorScheme,      appender.layout.color_scheme
      assert_equal 'log/dev.log', appender.name
      assert_equal '%d : %m\n',   appender.layout.pattern
    end

  end

  class FileDataTests < UnitTests
    desc "FilData"
    setup do
      @data = FileData.new
    end
    subject{ @data }

    should have_imeths :path

  end

  class SyslogTests < UnitTests
    desc "SyslogTests"
    setup do
      @logger = OpenStruct.new
      @logger.debug_level = :white
      @logger.pattern  = '%d : %m\n'
      @logger.identity = "whatever"
      @logger.facility = ::Syslog::LOG_LOCAL3

      Logsly.colors('a_color_scheme') do |logger|
        debug logger.debug_level
      end

      @out = Syslog.new do |logger|
        identity logger.identity
        facility logger.facility

        pattern logger.pattern
        colors  'a_color_scheme'
      end
    end
    subject{ @out }

    should "be a Base output" do
      assert_kind_of Base, subject
    end

    should "build a Logsly::Logging182 syslog appender, passing args to the builds" do
      appender = subject.to_appender @logger

      assert_kind_of Logsly::Logging182::Appenders::Syslog, appender
      assert_kind_of Logsly::Logging182::Layouts::Pattern,  appender.layout
      assert_kind_of Logsly::Logging182::ColorScheme,       appender.layout.color_scheme
      assert_equal '%d : %m\n', appender.layout.pattern
    end

  end

  class SyslogDataTests < UnitTests
    desc "SyslogData"
    setup do
      @data = SyslogData.new
    end
    subject{ @data }

    should have_imeth :identity, :log_opts, :facility

    should "default :log_opts" do
      assert_equal (::Syslog::LOG_PID | ::Syslog::LOG_CONS), subject.log_opts
    end

    should "default :facility" do
      assert_equal ::Syslog::LOG_LOCAL0, subject.facility
    end

  end

end

