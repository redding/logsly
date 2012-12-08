require 'assert'
require 'logging'
require 'logsly/settings'
require 'logsly/base_output'

class Logsly::BaseOutput

  class DataTests < Assert::Context
    desc "the BaseOutputData handler"
    setup do
      Logsly.colors('a_color_scheme') do
        debug :white
      end
      @arg = '%d : %m\n'
      @lay = Logsly::BaseOutputData.new(@arg) do |*args|
        pattern args.first
        colors  'a_color_scheme'
      end
    end
    subject { @lay }

    should have_readers :pattern, :colors

    should "know its defaults" do
      lay = Logsly::BaseOutputData.new {}
      assert_equal '%m\n', lay.pattern
      assert_nil lay.colors
    end

    should "instance exec its build with args" do
      assert_equal '%d : %m\n',      subject.pattern
      assert_equal 'a_color_scheme', subject.colors
    end

    should "know its layout pattern opts hash" do
      expected = {
        :pattern      => subject.pattern,
        :color_scheme => "#{subject.colors}-#{@arg.object_id}"
      }
      assert_equal expected, subject.to_pattern_opts

      out = Logsly::BaseOutputData.new do
        pattern '%m\n'
      end
      out_expected = {:pattern => out.pattern}
      assert_equal out_expected, out.to_pattern_opts
    end

  end

  class BaseTests < Assert::Context
    desc "the BaseOutput handler"
    setup do
      @out = Logsly::BaseOutput.new {}
    end
    subject { @out }

    should have_reader :build
    should have_imeths :to_layout, :to_appender

    should "know its build" do
      build_proc = Proc.new {}
      out = Logsly::BaseOutput.new &build_proc

      assert_same build_proc, out.build
    end

    should "expect `to_appender` to be defined by subclasses" do
      assert_raises NotImplementedError do
        subject.to_appender
      end
    end

  end

  class BuildTests < BaseTests
    desc "given a build"
    setup do
      Logsly.colors('a_color_scheme') do
        debug :white
      end
      @out = Logsly::BaseOutput.new do |*args|
        pattern args.to_s
        colors  'a_color_scheme'
      end
    end

    should "build a Logging pattern layout" do
      data = Logsly::BaseOutputData.new('%d : %m\n', &@out.build)
      lay = subject.to_layout(data)

      assert_kind_of Logging::Layout, lay
      assert_equal   '%d : %m\n', lay.pattern
      assert_kind_of Logging::ColorScheme, lay.color_scheme
    end

  end

end

