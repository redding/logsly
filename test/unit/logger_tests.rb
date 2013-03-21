require 'assert'
require 'logging'
require 'logsly'
require 'test/support/logger'

module Logsly

  class BaseTests < Assert::Context
    desc "a logger with Logsly mixed in"
    setup do
      Logsly.reset
      @logger = TestLogger.new(:testy_log_logger)
    end
    subject { @logger }

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

  end

  class LoggerTests < BaseTests

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

  class AppenderTests < LoggerTests
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

    protected

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
