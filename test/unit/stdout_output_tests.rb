require 'assert'
require 'logsly/stdout_output'

class Logsly::StdoutOutput

  class BaseTests < Assert::Context
    desc "the StdoutOutput handler"
    setup do
      @out = Logsly::StdoutOutput.new {}
    end
    subject { @out }

    should "be an output handler" do
      assert_kind_of Logsly::BaseOutput, subject
    end

    should "build a Logging stdout appender"
  end

end

