# This class provides a DSL for setting color scheme values and lazy eval's
# the DSL to generate a Logging color scheme object.
# See https://github.com/TwP/logging/blob/logging-1.8.2/lib/logging/color_scheme.rb
# for details on Logging color schemes.

module Logsly

  class NullColors
    def to_scheme(*args); nil;  end
  end

  class Colors

    attr_reader :name, :build

    def initialize(name, &build)
      @name, @build = name, build
    end

    def to_scheme(*args)
      "#{@name}-#{args.map{|a| a.object_id}.join('-')}".tap do |scheme_name|
        Logsly::Logging182.color_scheme(scheme_name, ColorsData.new(*args, &@build).to_scheme_opts)
      end
    end

  end

  class ColorsData

    def initialize(*args, &build)
      self.instance_exec(*args, &build)

      @properties     = properties.map{ |p| self.send(p) }
      @method         = self.method_name
      @level_settings = levels.map{ |l| self.send(l) }
      @line_settings  = levels.map{ |l| self.send("#{l}_line") }

      if has_level_settings? && has_line_settings?
        raise ArgumentError, "can't set line and level settings in the same scheme"
      end
    end

    # color for the level text only

    def debug(value = nil)
      @debug = value if !value.nil?
      @debug
    end

    def info(value = nil)
      @info = value if !value.nil?
      @info
    end

    def warn(value = nil)
      @warn = value if !value.nil?
      @warn
    end

    def error(value = nil)
      @error = value if !value.nil?
      @error
    end

    def fatal(value = nil)
      @fatal = value if !value.nil?
      @fatal
    end

    # color for the entire log message based on the value of the log level

    def debug_line(value = nil)
      @debug_line = value if !value.nil?
      @debug_line
    end

    def info_line(value = nil)
      @info_line = value if !value.nil?
      @info_line
    end

    def warn_line(value = nil)
      @warn_line = value if !value.nil?
      @warn_line
    end

    def error_line(value = nil)
      @error_line = value if !value.nil?
      @error_line
    end

    def fatal_line(value = nil)
      @fatal_line = value if !value.nil?
      @fatal_line
    end

    # [%c] name of the logger that generate the log event
    def logger(value = nil)
      @logger = value if !value.nil?
      @logger
    end

    # [%d] datestamp
    def date(value = nil)
      @date = value if !value.nil?
      @date
    end

    # [%m] the user supplied log message
    def message(value = nil)
      @message = value if !value.nil?
      @message
    end

    # [%p] PID of the current process
    def pid(value = nil)
      @pid = value if !value.nil?
      @pid
    end

    # [%r] the time in milliseconds since the program started
    def time(value = nil)
      @time = value if !value.nil?
      @time
    end

    # [%T] the name of the thread Thread.current[:name]
    def thread(value = nil)
      @thread = value if !value.nil?
      @thread
    end

    # [%t] object_id of the thread
    def thread_id(value = nil)
      @thread_id = value if !value.nil?
      @thread_id
    end

    # [%F] filename where the logging request was issued
    def file(value = nil)
      @file = value if !value.nil?
      @file
    end

    # [%L] line number where the logging request was issued
    def line(value = nil)
      @line = value if !value.nil?
      @line
    end

    # [%M] method name where the logging request was issued
    def method_name(value = nil)
      @method_name = value if !value.nil?
      @method_name
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
