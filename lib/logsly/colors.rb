require 'ns-options'

# This class provides a DSL for setting color scheme values and lazy eval's
# the DSL to generate a Logging color scheme object.
# See https://github.com/TwP/logging/blob/master/lib/logging/color_scheme.rb
# for details on Logging color schemes.

module Logsly
  class Colors
    include NsOptions::Proxy

    # color for the level text only
    option :debug
    option :info
    option :warn
    option :error
    option :fatal

    # color for the entire log message based on the value of the log level
    option :debug_line
    option :info_line
    option :warn_line
    option :error_line
    option :fatal_line

    option :logger      # [%c] name of the logger that generate the log event
    option :date        # [%d] datestamp
    option :message     # [%m] the user supplied log message
    option :pid         # [%p] PID of the current process
    option :time        # [%r] the time in milliseconds since the program started
    option :thread      # [%T] the name of the thread Thread.current[:name]
    option :thread_id   # [%t] object_id of the thread
    option :file        # [%F] filename where the logging request was issued
    option :line        # [%L] line number where the logging request was issued
    option :method      # [%M] method name where the logging request was issued

    attr_reader :build

    def initialize(&build)
      @build = build
    end

    def run_build
      self.instance_eval &@build
    end

  end
end
