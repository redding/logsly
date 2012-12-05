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

    should have_imeths :build, :pattern, :colors, :run_build, :to_layout

    should "know its build" do
      build_proc = Proc.new {}
      out = Logsly::BaseOutput.new &build_proc

      assert_same build_proc, out.build
    end

  end

  class BuildTests < BaseTests
    desc "given a build"
    setup do
      Logging.color_scheme('a_color_scheme', {
        :debug => :white
      })
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

    should "build a Logging pattern layout" do
      subject.run_build
      lay = subject.to_layout

      assert_kind_of Logging::Layout, lay
      assert_equal '%m\n', lay.pattern
      assert_kind_of Logging::ColorScheme, lay.color_scheme
    end

  end

end

