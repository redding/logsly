require 'assert'
require 'logsly/file_output'

require 'logging'
require 'ostruct'
require 'logsly'

class Logsly::FileOutput

  class UnitTests < Assert::Context
    desc "Logsly::FileOutput"
    setup do
      @logger = OpenStruct.new
      @logger.debug_level = :white
      @logger.pattern = '%d : %m\n'
      @logger.file = "log/dev.log"

      Logsly.colors('a_color_scheme') do |logger|
        debug logger.debug_level
      end

      @out = Logsly::FileOutput.new do |logger|
        path logger.file

        pattern logger.pattern
        colors  'a_color_scheme'
      end
    end
    subject{ @out }

    should "be an output handler" do
      assert_kind_of Logsly::BaseOutput, subject
    end

    should "build a Logging file appender, passing args to the builds" do
      appender = subject.to_appender @logger

      assert_kind_of Logging::Appenders::File,  appender
      assert_equal   'log/dev.log',             appender.name
      assert_kind_of Logging::Layouts::Pattern, appender.layout
      assert_equal   '%d : %m\n',               appender.layout.pattern
      assert_kind_of Logging::ColorScheme,      appender.layout.color_scheme
    end

  end

  class FileOutputDataTests < Assert::Context
    desc "FileOutputData"
    setup do
      @data = Logsly::FileOutputData.new {}
    end
    subject{ @data }

    should have_imeth :path

  end

end
