require 'assert'
require 'logsly/base_output'

class Logsly::BaseOutput

  class BaseTests < Assert::Context
    desc "the BaseOutput handler"
    setup do
      @out = Logsly::BaseOutput.new {}
    end
    subject { @out }

    should have_imeths :build, :pattern, :colors, :run_build

    should "know its build" do
      build_proc = Proc.new {}
      out = Logsly::BaseOutput.new &build_proc

      assert_same build_proc, out.build
    end

    should "instance eval its build" do
      out = Logsly::BaseOutput.new do
        pattern 'abcd'
        colors  'a_color_scheme'
      end

      assert_nil out.pattern
      assert_nil out.colors

      out.run_build

      assert_equal 'abcd', out.pattern
      assert_equal 'a_color_scheme', out.colors
    end

  end

end

