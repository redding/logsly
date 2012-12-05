require 'ns-options'

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

  end
end
