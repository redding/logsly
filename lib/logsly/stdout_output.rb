require 'logging'
require 'logsly/base_output'

module Logsly
  class StdoutOutput < BaseOutput
    def to_appender
      @appender = Logging.appenders.stdout(:layout => self.to_layout) if @appender.nil?
      @appender
    end
  end
end
