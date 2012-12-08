require 'ostruct'
require 'ns-options'

# This class provides a DSL for setting color scheme values and lazy eval's
# the DSL to generate a Logging color scheme object.
# See https://github.com/TwP/logging/blob/master/lib/logging/color_scheme.rb
# for details on Logging color schemes.

module Logsly

  class NullColors < OpenStruct
    def initialize(&build); super(); end
    def run_build; self; end
    def to_scheme; nil;  end
  end

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
    option :method_name # [%M] method name where the logging request was issued

    attr_reader :name, :build, :scheme

    def initialize(name, &build)
      @name, @build, @scheme = name, build, nil

      @properties     = []
      @method         = nil
      @level_settings = []
      @line_settings  = []
    end

    def run_build(*args)
      self.instance_exec(*args, &@build)

      @properties     = properties.map{|p| self.send(p)}
      @method         = self.method_name
      @level_settings = levels.map{|l| self.send(l)}
      @line_settings  = levels.map{|l| self.send("#{l}_line")}

      if has_level_settings? && has_line_settings?
        raise ArgumentError, "can't set line and level settings in the same scheme"
      end

      @scheme = Logging.color_scheme(@name, self.to_scheme_opts)
      self
    end

    def to_scheme_opts
      Hash.new.tap do |opts|
        # set general properties
        properties.each_with_index do |property, idx|
          opts[property] = @properties[idx] if @properties[idx]
        end

        # set special properties (reserved names)
        opts[:method] = @method if @method

        # set level settings - only add :levels key if one exists
        if has_level_settings?
          opts[:levels] = {}
          levels.each_with_index do |level, idx|
            opts[:levels][level] = @level_settings[idx] if @level_settings[idx]
          end
        end

        # set line-level settings - only :lines key if one exists
        if has_line_settings?
          opts[:lines] = {}
          levels.each_with_index do |level, idx|
            opts[:lines][level] = @line_settings[idx] if @line_settings[idx]
          end
        end
      end
    end

    private

    def has_level_settings?; !@level_settings.compact.empty?; end
    def has_line_settings?;  !@line_settings.compact.empty?;  end

    def properties
      [:logger, :date, :message, :time, :pid, :thread, :thread_id, :file, :line]
    end

    def levels
      [:debug, :info, :warn, :error, :fatal]
    end

  end
end
