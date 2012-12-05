require 'assert'
require 'logsly/colors'

class Logsly::Colors

  class BaseTests < Assert::Context
    desc "the Colors handler"
    setup do
      @out = Logsly::Colors.new {}
    end
    subject { @out }

    should have_imeths :build
    should have_imeths :debug, :info, :warn, :error, :fatal
    should have_imeths :debug_line, :info_line, :warn_line, :error_line, :fatal_line
    should have_imeths :logger, :date, :message, :pid, :time, :thread, :thread_id
    should have_imeths :file, :line, :method

    should "know its build" do
      build_proc = Proc.new {}
      out = Logsly::Colors.new &build_proc

      assert_same build_proc, out.build
    end

    should "instance eval its build" do
      colors = Logsly::Colors.new do
        debug_line :magenta
        fatal [:white, :on_red]

        date :blue
      end

      assert_nil colors.debug_line
      assert_nil colors.fatal
      assert_nil colors.date
      assert_nil colors.message

      colors.run_build

      assert_equal :magenta,          colors.debug_line
      assert_equal [:white, :on_red], colors.fatal
      assert_equal :blue,             colors.date
      assert_nil   colors.message
    end

    should "build a Logging color scheme"

  end

end

