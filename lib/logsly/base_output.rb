require 'ostruct'
require 'ns-options'
require 'logging'

module Logsly

  class NullOutput < OpenStruct
    def to_appender(*args); nil; end
    def to_layout(*args);   nil; end
  end

  class BaseOutput

    attr_reader :build

    def initialize(&build)
      @build = build || Proc.new {}
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

  class BaseOutputData
    include NsOptions::Proxy
    option :pattern, String, :default => '%m\n'
    option :colors,  String

    def initialize(*args, &build)
      @args = args
      self.instance_exec(*@args, &build)
    end

    def to_pattern_opts
      Hash.new.tap do |opts|
        opts[:pattern] = self.pattern if self.pattern

        if scheme_name = colors_obj.to_scheme(*@args)
          opts[:color_scheme] = scheme_name
        end
      end
    end

    protected

    def colors_obj
      Logsly.colors(self.colors)
    end

  end

end
