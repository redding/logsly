require 'assert'
require 'logsly/settings'

module Logsly

  class SettingsTests < Assert::Context
    desc "Logsly settings"
    setup do
      Logsly::Settings.reset
    end
    subject { Logsly }

    should have_imeths :reset, :colors, :stdout, :file, :syslog, :outputs

    should "return a NullColors obj when requesting a color scheme that isn't defined" do
      assert_kind_of NullColors, Logsly.colors('not_defined_yet')
    end

    should "add a named color scheme using the `colors` method" do
      assert_kind_of NullColors, Logsly.colors('test_colors')
      Logsly.colors('test_colors') {}

      assert_kind_of Colors, Logsly.colors('test_colors')
    end

    should "add a named stdout output using the `stdout` method" do
      assert_nil Logsly.outputs('test_stdout')
      Logsly.stdout('test_stdout') {}

      assert_not_nil Logsly.outputs('test_stdout')
      assert_kind_of StdoutOutput, Logsly.outputs('test_stdout')
    end

    should "add a named file output using the `file` method" do
      assert_nil Logsly.outputs('test_file')
      Logsly.file('test_file') {}

      assert_not_nil Logsly.outputs('test_file')
      assert_kind_of FileOutput, Logsly.outputs('test_file')
    end

    should "add a named syslog output using the `syslog` method" do
      assert_nil Logsly.outputs('test_syslog')
      Logsly.syslog('test_syslog') {}

      assert_not_nil Logsly.outputs('test_syslog')
      assert_kind_of SyslogOutput, Logsly.outputs('test_syslog')
    end

    should "convert non-string setting names to string" do
      Logsly.colors(:test_colors) {}

      assert_not_nil Logsly.colors(:test_colors)
      assert_kind_of Colors, Logsly.colors(:test_colors)
    end

    should "overwrite same-named colors settings" do
      Logsly.colors('something') {}
      orig = Logsly.colors('something')
      Logsly.colors('something') {}

      assert_not_same orig, Logsly.colors('something')
    end

    should "overwrite same-named outputs settings" do
      Logsly.stdout('something') {}
      assert_kind_of StdoutOutput, Logsly.outputs('something')

      Logsly.file('something') {}
      assert_kind_of FileOutput, Logsly.outputs('something')
    end

  end

  class ResetTests < SettingsTests
    desc "`reset` method"
    setup do
      Logsly.colors('test_colors') {}
      Logsly.stdout('test_stdout') {}
    end

    should "reset the Settings" do
      assert_kind_of Colors,       Logsly.colors('test_colors')
      assert_kind_of StdoutOutput, Logsly.outputs('test_stdout')

      Logsly.reset

      assert_kind_of NullColors, Logsly.colors('test_colors')
      assert_nil     Logsly.outputs('test_stdout')
    end

  end

end
