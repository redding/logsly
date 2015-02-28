require 'assert'
require 'logsly/stdout_output'

require 'ostruct'
require 'logging'
require 'logsly'

class Logsly::StdoutOutput

  class UnitTests < Assert::Context
    desc "Logsly::StdoutOutput"
    setup do
      @logger = OpenStruct.new
      @logger.debug_level = :white
      @logger.pattern = '%d : %m\n'

      Logsly.colors('a_color_scheme') do |logger|
        debug logger.debug_level
      end

      @out = Logsly::StdoutOutput.new do |logger|
        pattern logger.pattern
        colors  'a_color_scheme'
      end
    end
    subject{ @out }

    should "be an output handler" do
      assert_kind_of Logsly::BaseOutput, subject
    end

    should "build a Logging stdout appender, passing args to the builds" do
      appender = subject.to_appender @logger

      assert_kind_of Logging::Appenders::Stdout, appender
      assert_kind_of Logging::Layouts::Pattern,  appender.layout
      assert_equal   '%d : %m\n',                appender.layout.pattern
      assert_kind_of Logging::ColorScheme,       appender.layout.color_scheme
    end

  end

end
