require 'assert'
require 'logging'
require 'logsly/colors'

class Logsly::Colors

  class BaseTests < Assert::Context
    desc "the Colors handler"
    setup do
      @colors = Logsly::Colors.new('test_colors') {}
    end
    subject { @colors }

    should have_readers :name, :build, :been_built, :scheme
    should have_imeths :run_build, :to_scheme_opts
    should have_imeths :debug, :info, :warn, :error, :fatal
    should have_imeths :debug_line, :info_line, :warn_line, :error_line, :fatal_line
    should have_imeths :logger, :date, :message, :pid, :time, :thread, :thread_id
    should have_imeths :file, :line, :method_name

    should "know its name" do
      assert_equal 'test_colors', subject.name
    end

    should "know its build" do
      build_proc = Proc.new {}
      out = Logsly::Colors.new 'test', &build_proc

      assert_same build_proc, out.build
    end

    should "know if its been built" do
      assert_not subject.been_built
      subject.run_build
      assert     subject.been_built
    end

    should "return itself when `run_build` is called" do
      assert_equal subject, subject.run_build
    end

    should "complian if setting both a level and a line setting" do
      both_lines_and_levels = Logsly::Colors.new 'test' do
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
      general_only = Logsly::Colors.new 'test' do
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
      no_levels_lines = Logsly::Colors.new('test') { date :blue }
      expected = { :date => :blue }
      no_levels_lines.run_build

      assert_equal expected, no_levels_lines.to_scheme_opts
    end

  end

  class BuildTests < BaseTests
    desc "given a build"
    setup do
      @colors = Logsly::Colors.new 'test' do
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

    should "build and know its Logging color scheme" do
      assert_nil subject.scheme
      subject.run_build
      assert_kind_of Logging::ColorScheme, subject.scheme
    end

  end

end

