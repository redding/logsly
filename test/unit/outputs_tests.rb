require 'assert'
require 'logsly/outputs'

require 'logsly/logging182'
require 'logsly'

module Logsly::Outputs

  class UnitTests < Assert::Context
    desc "Logsly::Outputs"
    subject{ @out }

    should "know its default pattern" do
      assert_equal '%m\n', Logsly::Outputs::DEFAULT_PATTERN
    end

  end

  class NullTests < UnitTests
    desc "Null"
    setup do
      @out = Null.new
    end

    should have_imeths :data, :to_layout, :to_appender

    should "know its data" do
      assert_nil subject.data
    end

    should "always return `nil` converting to a layout/appender" do
      assert_nil subject.to_layout(Factory.string)
      assert_nil subject.to_appender(Factory.string)
    end

  end

  class BaseTests < UnitTests
    desc "Base"
    setup do
      @out = Base.new
    end

    should have_reader :build
    should have_imeths :data, :to_layout, :to_appender

    should "know its build" do
      build_proc = Proc.new{}
      out = Base.new(&build_proc)

      assert_same build_proc, out.build
    end

    should "expect `data` and `to_appender` to be defined by subclasses" do
      assert_raises(NotImplementedError){ subject.data }
      assert_raises NotImplementedError do
        subject.to_appender(Factory.string)
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
        level   'info'
      end
    end
    subject{ @data }

    should have_imeths :pattern, :colors, :level

    should "know its defaults" do
      data = BaseData.new
      assert_equal DEFAULT_PATTERN, data.pattern
      assert_nil data.colors
      assert_nil data.level
    end

    should "instance exec its build with args" do
      assert_equal '%d : %m\n',      subject.pattern
      assert_equal 'a_color_scheme', subject.colors
      assert_equal 'info',           subject.level
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
        level   'info'
      end
    end
    subject{ @out }

    should "be a Base output" do
      assert_kind_of Base, subject
    end

    should "know its data" do
      data = subject.data(@logger)
      assert_instance_of BaseData, data
      assert_equal @logger.pattern,  data.pattern
      assert_equal 'a_color_scheme', data.colors
      assert_equal 'info',           data.level
    end

    should "build a Logsly::Logging182 stdout appender, passing args to the builds" do
      appender = subject.to_appender(subject.data(@logger))

      assert_kind_of Logsly::Logging182::Appenders::Stdout, appender
      assert_kind_of Logsly::Logging182::Layouts::Pattern,  appender.layout
      assert_kind_of Logsly::Logging182::ColorScheme,       appender.layout.color_scheme
      assert_equal @logger.pattern, appender.layout.pattern
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
        level   'info'
      end
    end
    subject{ @out }

    should "be a Base output" do
      assert_kind_of Base, subject
    end

    should "know its data" do
      data = subject.data(@logger)
      assert_instance_of FileData, data
      assert_equal @logger.file,     data.path
      assert_equal @logger.pattern,  data.pattern
      assert_equal 'a_color_scheme', data.colors
      assert_equal 'info',           data.level
    end

    should "build a Logsly::Logging182 file appender, passing args to the builds" do
      appender = subject.to_appender(subject.data(@logger))

      assert_kind_of Logsly::Logging182::Appenders::File,  appender
      assert_kind_of Logsly::Logging182::Layouts::Pattern, appender.layout
      assert_kind_of Logsly::Logging182::ColorScheme,      appender.layout.color_scheme
      assert_equal @logger.file,    appender.name
      assert_equal @logger.pattern, appender.layout.pattern
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
        level   'info'
      end
    end
    subject{ @out }

    should "be a Base output" do
      assert_kind_of Base, subject
    end

    should "know its data" do
      data = subject.data(@logger)
      assert_instance_of SyslogData, data
      assert_equal @logger.identity, data.identity
      assert_equal @logger.facility, data.facility
      assert_equal @logger.pattern,  data.pattern
      assert_equal 'a_color_scheme', data.colors
      assert_equal 'info',           data.level
    end

    should "build a Logsly::Logging182 syslog appender, passing args to the builds" do
      appender = subject.to_appender(subject.data(@logger))

      assert_kind_of Logsly::Logging182::Appenders::Syslog, appender
      assert_kind_of Logsly::Logging182::Layouts::Pattern,  appender.layout
      assert_kind_of Logsly::Logging182::ColorScheme,       appender.layout.color_scheme
      assert_equal @logger.pattern, appender.layout.pattern
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

