require 'assert'
require 'logging'
require 'logsly/base_output'

class Logsly::BaseOutput

  class BaseTests < Assert::Context
    desc "the BaseOutput handler"
    setup do
      @out = Logsly::BaseOutput.new {}
    end
    subject { @out }

    should have_imeths :build, :pattern, :colors, :colors_obj, :color_scheme
    should have_imeths :run_build, :to_layout, :to_pattern_opts

    should "know its build" do
      build_proc = Proc.new {}
      out = Logsly::BaseOutput.new &build_proc

      assert_same build_proc, out.build
    end

    should "know its default color scheme" do
      assert_nil subject.color_scheme
    end

  end

  class BuildTests < BaseTests
    desc "given a build"
    setup do
      Logsly.colors('a_color_scheme') do
        debug :white
      end
      @out = Logsly::BaseOutput.new do
        pattern '%m\n'
        colors  'a_color_scheme'
      end
    end

    should "instance eval its build" do
      assert_nil subject.pattern
      assert_nil subject.colors

      subject.run_build

      assert_equal '%m\n', subject.pattern
      assert_equal 'a_color_scheme', subject.colors
    end

    should "know and run the build on its colors obj" do
      subject.run_build

      assert_kind_of Logsly::Colors, subject.colors_obj
      puts subject.colors_obj.inspect
      assert_equal :white, subject.colors_obj.debug
    end

    should "build and know its logging color scheme" do
      assert_nil subject.color_scheme
      subject.run_build
      assert_equal 'a_color_scheme', subject.color_scheme
    end

    should "know its layout pattern opts hash" do
      subject.run_build
      expected = {
        :pattern      => subject.pattern,
        :color_scheme => subject.color_scheme
      }
      assert_equal expected, subject.to_pattern_opts

      out = Logsly::BaseOutput.new do
        pattern '%m\n'
      end
      out.run_build
      out_expected = {:pattern => subject.pattern}
      assert_equal out_expected, out.to_pattern_opts
    end

    should "build a Logging pattern layout" do
      subject.run_build
      lay = subject.to_layout

      assert_kind_of Logging::Layout, lay
      assert_equal   '%m\n', lay.pattern
      assert_kind_of Logging::ColorScheme, lay.color_scheme
    end

  end

end

