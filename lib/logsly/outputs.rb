require 'ns-options'
require 'logging'
require 'ostruct'
require 'syslog'

module Logsly; end
module Logsly::Outputs

  ## NULL

  class Null < OpenStruct
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
    include NsOptions::Proxy
    option :pattern, String, :default => '%m\n'
    option :colors,  String

    def initialize(*args, &build)
      @args = args
      self.instance_exec(*@args, &(build || Proc.new{}))
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
    option :path, String
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
    option :identity, String
    option :log_opts, Integer, :default => (::Syslog::LOG_PID | ::Syslog::LOG_CONS)
    option :facility, Integer, :default => ::Syslog::LOG_LOCAL0
  end

end
