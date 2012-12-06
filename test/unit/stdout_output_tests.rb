require 'assert'
require 'ostruct'
require 'logging'
require 'logsly/stdout_output'

class Logsly::StdoutOutput

  class BaseTests < Assert::Context
    desc "the StdoutOutput handler"
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
    subject { @out }

    should "be an output handler" do
      assert_kind_of Logsly::BaseOutput, subject
    end

    should "build a Logging stdout appender, passing args to the builds" do
      subject.run_build @logger

      assert_kind_of Logging::Appenders::Stdout, subject.to_appender
      assert_kind_of Logging::Layouts::Pattern, subject.to_appender.layout
      assert_equal   '%d : %m\n', subject.to_appender.layout.pattern
      assert_kind_of Logging::ColorScheme, subject.to_appender.layout.color_scheme
    end
  end

end
