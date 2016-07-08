require 'syslog'
require 'logsly/logging182'

module Logsly; end
module Logsly::Outputs

  DEFAULT_PATTERN = '%m\n'.freeze # log the message only

  ## NULL

  class Null
    def data(*args);       nil; end
    def to_layout(data);   nil; end
    def to_appender(data); nil; end
  end

  ## BASE

  class Base

    attr_reader :build

    def initialize(&build)
      @build = build || Proc.new{}
    end

    def data(*args)
      raise NotImplementedError
    end

    def to_layout(data)
      Logsly::Logging182.layouts.pattern(data.to_pattern_opts)
    end

    def to_appender(data)
      raise NotImplementedError
    end

  end

  class BaseData

    def initialize(*args, &build)
      @pattern = DEFAULT_PATTERN
      @colors  = nil
      @level   = nil

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

    def level(value = nil)
      @level = value if !value.nil?
      @level
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

    def data(*args)
      BaseData.new(*args, &self.build)
    end

    def to_appender(data)
      Logsly::Logging182.appenders.stdout(:layout => self.to_layout(data))
    end

  end

  ## FILE

  class File < Base

    def data(*args)
      FileData.new(*args, &self.build)
    end

    def to_appender(data)
      Logsly::Logging182.appenders.file(data.path, :layout => self.to_layout(data))
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

    def data(*args)
      SyslogData.new(*args, &self.build)
    end

    def to_appender(data)
      ::Syslog.close if ::Syslog.opened?

      Logsly::Logging182.appenders.syslog(data.identity, {
        :logopt   => data.log_opts,
        :facility => data.facility,
        :layout   => self.to_layout(data)
      })
    end

  end

  class SyslogData < BaseData

    def initialize(*args, &build)
      @log_opts = (::Syslog::LOG_PID | ::Syslog::LOG_CONS)
      @facility = ::Syslog::LOG_LOCAL0
      super
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
