require 'assert'
require 'logsly/file_output'

class Logsly::FileOutput

  class BaseTests < Assert::Context
    desc "the FileOutput handler"
    setup do
      @out = Logsly::FileOutput.new {}
    end
    subject { @out }

    should "be an output handler" do
      assert_kind_of Logsly::BaseOutput, subject
    end

    should "build a file Logging appender"
  end

end

