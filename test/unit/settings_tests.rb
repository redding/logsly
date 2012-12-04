require 'assert'
require 'logsly/settings'

module Logsly

  class SettingsTests < Assert::Context
    desc "Logsly"
    setup do
      Logsly::Settings.reset
    end
    subject { Logsly }

    should have_imeths :colors, :stdout, :file, :syslog, :outputs

    should "add a named color scheme using the `colors` method" do
      assert_nil Logsly.colors('test_colors')
      subject.colors('test_colors') {}

      assert_not_nil Logsly.colors('test_colors')
      assert_kind_of Colors, Logsly.colors('test_colors')
    end

    should "add a named stdout output using the `stdout` method" do
      assert_nil Logsly.outputs('test_stdout')
      subject.stdout('test_stdout') {}

      assert_not_nil Logsly.outputs('test_stdout')
      assert_kind_of StdoutOutput, Logsly.outputs('test_stdout')
    end

    should "add a named file output using the `file` method" do
      assert_nil Logsly.outputs('test_file')
      subject.file('test_file') {}

      assert_not_nil Logsly.outputs('test_file')
      assert_kind_of FileOutput, Logsly.outputs('test_file')
    end

    should "add a named syslog output using the `syslog` method" do
      assert_nil Logsly.outputs('test_syslog')
      subject.syslog('test_syslog') {}

      assert_not_nil Logsly.outputs('test_syslog')
      assert_kind_of SyslogOutput, Logsly.outputs('test_syslog')
    end

    should "convert non-string setting names to string" do
      subject.colors(:test_colors) {}

      assert_not_nil Logsly.colors(:test_colors)
      assert_kind_of Colors, Logsly.colors(:test_colors)
    end

    should "overwrite same-named colors settings" do
      subject.colors('something') {}
      orig = Logsly.colors('something')
      subject.colors('something') {}

      assert_not_same orig, Logsly.colors('something')
    end

    should "overwrite same-named outputs settings" do
      subject.stdout('something') {}
      assert_kind_of StdoutOutput, Logsly.outputs('something')

      subject.file('something') {}
      assert_kind_of FileOutput, Logsly.outputs('something')
    end

  end

end
