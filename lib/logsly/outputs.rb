require 'logging'
require 'syslog'

module Logsly; end
module Logsly::Outputs

  ## NULL

  class Null
    def to_appender(*args); nil; end
    def to_layout(*args);   nil; end
  end

  ## BASE

  class Base

    attr_reader :build

    def initialize(&build)
      @build = build || Proc.new{}
    end

    def to_appender(*args)
      self.instance_exec(*args, &@build)
      self.colors_obj.run_build(*args)
      self
    end

    def to_layout(data)
      Logging.layouts.pattern(data.to_pattern_opts)
    end

    def to_appender(*args)
      raise NotImplementedError
    end

  end

  class BaseData

    def initialize(*args, &build)
      @pattern = '%m\n'
      @colors  = nil

      @args = args
      self.instance_exec(*@args, &(build || Proc.new{}))
    end

    def pattern(value = nil)
      @pattern = value if !value.nil?
      @pattern
    end

    def colors(value = nil)
      @colors = value if !value.nil?
      @colors
    end

    def to_pattern_opts
      Hash.new.tap do |opts|
        opts[:pattern] = self.pattern if self.pattern

        if scheme_name = colors_obj.to_scheme(*@args)
          opts[:color_scheme] = scheme_name
        end
      end
    end

    private

    def colors_obj
      Logsly.colors(self.colors)
    end

  end

  ## STDOUT

  class Stdout < Base

    def to_appender(*args)
      data = BaseData.new(*args, &self.build)
      Logging.appenders.stdout(:layout => self.to_layout(data))
    end

  end

  ## FILE

  class File < Base

    def to_appender(*args)
      data = FileData.new(*args, &self.build)
      Logging.appenders.file(data.path, :layout => self.to_layout(data))
    end

  end

  class FileData < BaseData

    def path(value = nil)
      @path = value if !value.nil?
      @path
    end

  end

  ## SYSLOG

  class Syslog < Base

    def to_appender(*args)
      ::Syslog.close if ::Syslog.opened?

      data = SyslogData.new(*args, &self.build)
      Logging.appenders.syslog(data.identity, {
        :logopt   => data.log_opts,
        :facility => data.facility,
        :layout   => self.to_layout(data)
      })
    end

  end

  class SyslogData < BaseData

    def initialize(*args, &build)
      super
      @log_opts = (::Syslog::LOG_PID | ::Syslog::LOG_CONS)
      @facility = ::Syslog::LOG_LOCAL0
    end

    def identity(value = nil)
      @identity = value if !value.nil?
      @identity
    end

    def log_opts(value = nil)
      @log_opts = value if !value.nil?
      @log_opts
    end

    def facility(value = nil)
      @facility = value if !value.nil?
      @facility
    end

  end

end
