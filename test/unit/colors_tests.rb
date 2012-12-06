require 'assert'
require 'logging'
require 'logsly/colors'

class Logsly::Colors

  class BaseTests < Assert::Context
    desc "the Colors handler"
    setup do
      @colors = Logsly::Colors.new {}
    end
    subject { @colors }

    should have_imeths :build, :run_build, :to_scheme, :to_scheme_opts
    should have_imeths :debug, :info, :warn, :error, :fatal
    should have_imeths :debug_line, :info_line, :warn_line, :error_line, :fatal_line
    should have_imeths :logger, :date, :message, :pid, :time, :thread, :thread_id
    should have_imeths :file, :line, :method_name

    should "know its build" do
      build_proc = Proc.new {}
      out = Logsly::Colors.new &build_proc

      assert_same build_proc, out.build
    end

    should "complian if setting both a level and a line setting" do
      both_lines_and_levels = Logsly::Colors.new do
        info       :blue
        debug_line :white
      end
      err = begin
        both_lines_and_levels.run_build
        nil
      rescue ArgumentError => err
        err
      end

      assert_kind_of ArgumentError, err
      assert_includes "can't set line and level settings in the same scheme", err.message
    end

    should "know its scheme opts hash and only include specified opts" do
      general_only = Logsly::Colors.new do
        date        :blue
        message     :cyan
        method_name :white
        info        :blue
      end
      expected = {
        :date    => :blue,
        :message => :cyan,
        :method  => :white,
        :levels  => {:info  => :blue},
      }
      general_only.run_build

      assert_equal expected, general_only.to_scheme_opts
    end

    should "only include :levels and :lines if at least one is set" do
      no_levels_lines = Logsly::Colors.new { date :blue }
      expected = { :date => :blue }
      no_levels_lines.run_build

      assert_equal expected, no_levels_lines.to_scheme_opts
    end

  end

  class BuildTests < BaseTests
    desc "given a build"
    setup do
      @colors = Logsly::Colors.new do
        fatal [:white, :on_red]
        date  :blue
      end
    end

    should "instance eval its build" do
      assert_nil subject.debug_line
      assert_nil subject.fatal
      assert_nil subject.date
      assert_nil subject.message

      subject.run_build

      assert_equal [:white, :on_red], subject.fatal
      assert_equal :blue,             subject.date
      assert_nil   subject.message
    end

    should "build a Logging color scheme" do
      subject.run_build
      scheme = nil

      assert_nothing_raised { scheme = subject.to_scheme }
      assert_kind_of Logging::ColorScheme, scheme
    end

  end

end

