require 'assert'
require 'logsly'

require 'logsly/logging182'
require 'logsly/colors'
require 'logsly/outputs'
require 'test/support/logger'

module Logsly

  class UnitTests < Assert::Context
    desc "Logsly"
    setup do
      Logsly.reset
    end
    subject{ Logsly }

    should have_imeths :reset, :colors, :stdout, :file, :syslog, :outputs

    should "know its default level" do
      assert_equal 'info', DEFAULT_LEVEL
    end

    should "return a NullColors obj when requesting a color scheme that isn't defined" do
      assert_kind_of NullColors, Logsly.colors('not_defined_yet')
    end

    should "return a NullOutput obj when requesting an output that isn't defined" do
      assert_kind_of Outputs::Null, Logsly.outputs('not_defined_yet')
    end

    should "add a named color scheme using the `colors` method" do
      assert_kind_of NullColors, Logsly.colors('test_colors')
      Logsly.colors('test_colors') {}

      assert_kind_of Colors, Logsly.colors('test_colors')
    end

    should "add a named stdout output using the `stdout` method" do
      assert_kind_of Outputs::Null, Logsly.outputs('test_stdout')
      Logsly.stdout('test_stdout') {}

      assert_not_nil Logsly.outputs('test_stdout')
      assert_kind_of Outputs::Stdout, Logsly.outputs('test_stdout')
    end

    should "add a named file output using the `file` method" do
      assert_kind_of Outputs::Null, Logsly.outputs('test_file')
      Logsly.file('test_file') {}

      assert_not_nil Logsly.outputs('test_file')
      assert_kind_of Outputs::File, Logsly.outputs('test_file')
    end

    should "add a named syslog output using the `syslog` method" do
      assert_kind_of Outputs::Null, Logsly.outputs('test_syslog')
      Logsly.syslog('test_syslog') {}

      assert_not_nil Logsly.outputs('test_syslog')
      assert_kind_of Outputs::Syslog, Logsly.outputs('test_syslog')
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
      assert_kind_of Outputs::Stdout, Logsly.outputs('something')

      Logsly.file('something') {}
      assert_kind_of Outputs::File, Logsly.outputs('something')
    end

  end

  class ResetTests < UnitTests
    desc "`reset` method"
    setup do
      Logsly.colors('test_colors') {}
      Logsly.stdout('test_stdout') {}
    end

    should "reset the settings" do
      assert_kind_of Colors,          Logsly.colors('test_colors')
      assert_kind_of Outputs::Stdout, Logsly.outputs('test_stdout')

      Logsly.reset

      assert_kind_of NullColors,    Logsly.colors('test_colors')
      assert_kind_of Outputs::Null, Logsly.outputs('test_stdout')
    end

  end

  class LoggerTests < UnitTests
    desc "logger"
    setup do
      # this populates the `Logsly::Logging182::LEVELS` constant
      Logsly::Logging182.init

      @logger = TestLogger.new(:testy_log_logger)
    end
    teardown do
      Logsly.reset
    end
    subject{ @logger }

    should have_readers :log_type, :level, :outputs, :output_loggers
    should have_imeths :mdc, :file_path
    should have_imeths *::Logger::Severity.constants.map{ |n| n.downcase.to_sym }
    should have_imeths *::Logger::Severity.constants.map{ |n| "#{n.downcase}?".to_sym }

    should "know its log_type" do
      assert_equal 'testy_log_logger', subject.log_type
    end

    should "know its default opt values" do
      assert_equal DEFAULT_LEVEL, subject.level
      assert_equal [],            subject.outputs
    end

    should "allow overridding the default opt values" do
      log = TestLogger.new(:testy_debug_logger, {
        :level   => :debug,
        :outputs => :stdout
      })
      assert_equal 'debug',   log.level
      assert_equal [:stdout], log.outputs
    end

    should "not have any output loggers by default" do
      assert_empty subject.output_loggers
    end

    should "create a Logsly::Logging182::Logger for each output" do
      outputs = Factory.integer(3).times.map{ Factory.string }
      log = TestLogger.new(:testy_log_logger, :outputs => outputs)
      assert_equal outputs.size, log.output_loggers.size
      outputs.each do |output|
        logger = log.output_loggers[output]
        assert_kind_of Logsly::Logging182::Logger, logger

        # set a unique name for  each logger
        exp = "#{log.class.name}-testy_log_logger-#{log.object_id}-#{output}"
        assert_equal exp, logger.name

        # default the level for each logger
        assert_equal Logsly::Logging182::LEVELS[DEFAULT_LEVEL], logger.level
      end
    end

    should "default a configured outputs level when creating loggers" do
      output_name = Factory.string
      Logsly.stdout(output_name){ } # don't set a `level`

      log = TestLogger.new(:testy_log_logger, :outputs => [output_name])
      logger = log.output_loggers[output_name]
      assert_kind_of Logsly::Logging182::Logger, logger
      assert_equal Logsly::Logging182::LEVELS[DEFAULT_LEVEL], logger.level
    end

    should "use the configured outputs level when creating loggers" do
      output_name      = Factory.string
      custom_log_level = Logsly::Logging182::LEVELS.keys.choice
      Logsly.stdout(output_name){ level(custom_log_level) }

      passed_log_level = (Logsly::Logging182::LEVELS.keys - [custom_log_level]).choice
      log = TestLogger.new(:testy_log_logger, {
        :level   => passed_log_level,
        :outputs => [output_name]
      })
      logger = log.output_loggers[output_name]
      assert_kind_of Logsly::Logging182::Logger, logger
      assert_equal Logsly::Logging182::LEVELS[custom_log_level], logger.level
    end

    should "use a passed output level when creating loggers" do
      output_name = Factory.string
      Logsly.stdout(output_name){ } # don't set a `level`

      passed_log_level = Logsly::Logging182::LEVELS.keys.choice
      log = TestLogger.new(:testy_log_logger, {
        :level   => passed_log_level,
        :outputs => [output_name]
      })
      logger = log.output_loggers[output_name]
      assert_kind_of Logsly::Logging182::Logger, logger
      assert_equal Logsly::Logging182::LEVELS[passed_log_level], logger.level
    end

    should "set mdc key/value pairs" do
      key = Factory.string
      assert_nil Logsly::Logging182.mdc[key]

      value = Factory.string
      subject.mdc(key, value)
      assert_equal value, Logsly::Logging182.mdc[key]
    end

    should "not have a file path if no file appender is specified" do
      assert_nil subject.file_path
    end

  end

  class AppenderTests < UnitTests
    setup do
      Logsly.stdout('my_stdout') do |logger|
        level 'debug'
      end
      Logsly.file('my_file') do |logger|
        path "log/development-#{logger.log_type}.log"
        level 'debug'
      end
      Logsly.file('my_other_file') do |logger|
        path "log/other-#{logger.log_type}.log"
      end
      Logsly.syslog('my_syslog') do |logger|
        identity "my_syslog_logger-#{logger.log_type}"
        level 'debug'
      end
    end

    should "add a named stdout appender and honor its level" do
      log = TestLogger.new(:test, :outputs => 'my_stdout')
      assert_includes_appender Logsly::Logging182::Appenders::Stdout, log
      assert_nil log.file_path

      exp = Logsly::Logging182::LEVELS['debug']
      assert_equal exp, log.output_loggers['my_stdout'].level
    end

    should "add a named file appender and honor its level" do
      log     = TestLogger.new(:test, :outputs => 'my_file')
      filelog = extract_appender_from_logger(log, :file)

      assert_includes_appender Logsly::Logging182::Appenders::File, log
      assert_equal 'log/development-test.log', filelog.name
      assert_equal 'log/development-test.log', log.file_path

      exp = Logsly::Logging182::LEVELS['debug']
      assert_equal exp, log.output_loggers['my_file'].level
    end

    should "add a named syslog appender and honor its level" do
      log = TestLogger.new(:test, :outputs => 'my_syslog')
      assert_includes_appender Logsly::Logging182::Appenders::Syslog, log
      assert_nil log.file_path

      exp = Logsly::Logging182::LEVELS['debug']
      assert_equal exp, log.output_loggers['my_syslog'].level
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
        Logsly::Logging182::Appenders::Syslog
      when :file
        Logsly::Logging182::Appenders::File
      when :stdout
        Logsly::Logging182::Appenders::Stdout
      end

      logger.appenders.detect{ |a| a.is_a?(klass) }
    end

  end

end
