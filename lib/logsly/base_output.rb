require 'ns-options'
require 'logging'
require 'logsly/settings'

module Logsly
  class BaseOutput
    include NsOptions::Proxy

    option :pattern, String
    option :colors,  String

    attr_reader :build

    def initialize(&build)
      @build = build
    end

    def run_build
      self.instance_eval &@build
    end

    def to_layout
      Logging.layouts.pattern(self.to_pattern_opts)
    end

    def to_pattern_opts
      Hash.new.tap do |opts|
        opts[:pattern]      = self.pattern      if self.pattern
        opts[:color_scheme] = self.color_scheme if self.color_scheme
      end
    end

    def color_scheme
      colors_obj.name
    end

    def colors_obj
      Logsly.colors(self.colors).run_build
    end

  end
end
