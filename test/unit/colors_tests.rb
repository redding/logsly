require 'assert'
require 'logsly/colors'

require 'logsly/logging182'

class Logsly::Colors

  class UnitTests < Assert::Context
    desc "Logsly::Colors"
    setup do
      @colors = Logsly::Colors.new('test_colors') do |*args|
        debug args.first
      end
    end
    subject{ @colors }

    should have_readers :name, :build
    should have_imeths  :to_scheme

    should "know its name" do
      assert_equal 'test_colors', subject.name
    end

    should "know its build" do
      build_proc = Proc.new{}
      out = Logsly::Colors.new 'test', &build_proc

      assert_same build_proc, out.build
    end

  end

  class BuildTests < UnitTests
    desc "given a build"
    setup do
      @colors = Logsly::Colors.new 'test' do |fatal_color|
        fatal [fatal_color, :on_red]
        date  :blue
      end
    end

    should "build a unique Logsly::Logging182 color scheme based on called args" do
      arg = 'white'
      scheme_name = subject.to_scheme(arg)

      assert_equal   "test-#{arg.object_id}", scheme_name
      assert_kind_of Logsly::Logging182::ColorScheme, Logsly::Logging182.color_scheme(scheme_name)
    end

  end

  class ColorsDataTests < Assert::Context
    desc "ColorsData"
    setup do
      @data = Logsly::ColorsData.new('white') do |color|
        debug color
      end
    end
    subject{ @data }

    should have_imeths :to_scheme_opts
    should have_imeths :debug, :info, :warn, :error, :fatal
    should have_imeths :debug_line, :info_line, :warn_line, :error_line, :fatal_line
    should have_imeths :logger, :date, :message, :pid, :time, :thread, :thread_id
    should have_imeths :file, :line, :method_name

    should "instance exec its build with args" do
      assert_equal 'white', subject.debug
    end

    should "complain if setting both a level and a line setting" do
      err = begin
        Logsly::ColorsData.new do
          info       :blue
          debug_line :white
        end
        nil
      rescue ArgumentError => err
        err
      end

      assert_kind_of ArgumentError, err
      assert_includes "can't set line and level settings in the same scheme", err.message
    end

    should "know its scheme opts hash and only include specified opts" do
      general_only = Logsly::ColorsData.new do
        date        :blue
        message     :cyan
        method_name :white
        info        :blue
      end
      exp = {
        :date    => :blue,
        :message => :cyan,
        :method  => :white,
        :levels  => {:info  => :blue},
      }

      assert_equal exp, general_only.to_scheme_opts
    end

    should "only include :levels and :lines if at least one is set" do
      no_levels_lines = Logsly::ColorsData.new { date :blue }
      exp = { :date => :blue }

      assert_equal exp, no_levels_lines.to_scheme_opts
    end

  end

end

