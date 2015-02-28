require 'assert'
require 'logsly'

require 'logging'
require 'test/support/logger'

module Logsly

  class UnitTests < Assert::Context
    desc "Logsly"
    setup do
      Logsly.reset
    end
    subject{ Logsly }

    should have_imeths :reset, :colors, :stdout, :file, :syslog, :outputs

    should "return a NullColors obj when requesting a color scheme that isn't defined" do
      assert_kind_of NullColors, Logsly.colors('not_defined_yet')
    end

    should "return a NullOutput obj when requesting an output that isn't defined" do
      assert_kind_of NullOutput, Logsly.outputs('not_defined_yet')
    end

    should "add a named color scheme using the `colors` method" do
      assert_kind_of NullColors, Logsly.colors('test_colors')
      Logsly.colors('test_colors') {}

      assert_kind_of Colors, Logsly.colors('test_colors')
    end

    should "add a named stdout output using the `stdout` method" do
      assert_kind_of NullOutput, Logsly.outputs('test_stdout')
      Logsly.stdout('test_stdout') {}

      assert_not_nil Logsly.outputs('test_stdout')
      assert_kind_of StdoutOutput, Logsly.outputs('test_stdout')
    end

    should "add a named file output using the `file` method" do
      assert_kind_of NullOutput, Logsly.outputs('test_file')
      Logsly.file('test_file') {}

      assert_not_nil Logsly.outputs('test_file')
      assert_kind_of FileOutput, Logsly.outputs('test_file')
    end

    should "add a named syslog output using the `syslog` method" do
      assert_kind_of NullOutput, Logsly.outputs('test_syslog')
      Logsly.syslog('test_syslog') {}

      assert_not_nil Logsly.outputs('test_syslog')
      assert_kind_of SyslogOutput, Logsly.outputs('test_syslog')
    end

    should "convert non-string setting names to string" do
      Logsly.colors(:test_colors) {}

      assert_not_nil Logsly.colors(:test_colors)
      assert_kind_of Colors, Logsly.colors(:test_colors)
    end

    should "overwrite same-named colors settings" do
      Logsly.colors('something') {}
      orig = Logsly.colors('something')
      Logsly.colors('something') {}

      assert_not_same orig, Logsly.colors('something')
    end

    should "overwrite same-named outputs settings" do
      Logsly.stdout('something') {}
      assert_kind_of StdoutOutput, Logsly.outputs('something')

      Logsly.file('something') {}
      assert_kind_of FileOutput, Logsly.outputs('something')
    end

  end

  class ResetTests < UnitTests
    desc "`reset` method"
    setup do
      Logsly.colors('test_colors') {}
      Logsly.stdout('test_stdout') {}
    end

    should "reset the Settings" do
      assert_kind_of Colors,       Logsly.colors('test_colors')
      assert_kind_of StdoutOutput, Logsly.outputs('test_stdout')

      Logsly.reset

      assert_kind_of NullColors, Logsly.colors('test_colors')
      assert_kind_of NullOutput, Logsly.outputs('test_stdout')
    end

  end

  class LoggerTests < UnitTests
    desc "logger"
    setup do
      @logger = TestLogger.new(:testy_log_logger)
    end
    subject{ @logger }

    should have_readers :log_type, :level, :outputs, :logger

    should "know its log_type" do
      assert_equal 'testy_log_logger', subject.log_type
    end

    should "know its default opt values" do
      assert_equal 'info', subject.level
      assert_equal [],     subject.outputs
    end

    should "allow overridding the default opt values" do
      log = TestLogger.new(:testy_debug_logger, :level => :debug, :outputs => [:stdout])
      assert_equal 'debug',   log.level
      assert_equal [:stdout], log.outputs
    end

    should "create a Logging::Logger" do
      assert_not_nil subject.logger
      assert_kind_of Logging::Logger, subject.logger
    end

    should "create the Logging::Logger with a unique name" do
      expected = "#{subject.class.name}-testy_log_logger-#{subject.object_id}"
      assert_equal expected, subject.logger.name
    end

    should "set the logger's level" do
      assert_equal Logging::LEVELS['info'], subject.logger.level

      log = TestLogger.new('test', :level => :debug)
      assert_equal Logging::LEVELS['debug'], log.logger.level
    end

  end

  class AppenderTests < UnitTests
    setup do
      Logsly.stdout 'my_stdout'
      Logsly.file('my_file') do |logger|
        path "log/development-#{logger.log_type}.log"
      end
      Logsly.file('my_other_file') do |logger|
        path "log/other-#{logger.log_type}.log"
      end
      Logsly.syslog('my_syslog') do |logger|
        identity "my_syslog_logger-#{logger.log_type}"
      end
    end

    should "add a named stdout appender" do
      log = TestLogger.new(:test, :outputs => 'my_stdout')
      assert_includes_appender Logging::Appenders::Stdout, log
    end

    should "add a named file appender" do
      log     = TestLogger.new(:test, :outputs => 'my_file')
      filelog = extract_appender_from_logger(log, :file)

      assert_includes_appender Logging::Appenders::File, log
      assert_equal 'log/development-test.log', filelog.name
    end

    should "add a named syslog appender" do
      log = TestLogger.new(:test, :outputs => 'my_syslog')
      assert_includes_appender Logging::Appenders::Syslog, log
    end

    should "not add duplicate appenders" do
      outputs = ['my_stdout', 'my_stdout', 'my_file', 'my_other_file']
      log = TestLogger.new(:test, :outputs => outputs)

      assert_equal 3, log.appenders.size
    end

    should "not add undefined appenders" do
      outputs = ['my_stdout', 'undefined']
      log = TestLogger.new(:test, :outputs => outputs)

      assert_equal 1, log.appenders.size
    end

    private

    def assert_includes_appender(appender_class, logger)
      assert_includes appender_class, logger.appenders.collect(&:class)
    end

    def extract_appender_from_logger(logger, type)
      klass = case type
      when :syslog
        Logging::Appenders::Syslog
      when :file
        Logging::Appenders::File
      when :stdout
        Logging::Appenders::Stdout
      end

      logger.appenders.select{|a| a.is_a?(klass)}.first
    end

  end

end
