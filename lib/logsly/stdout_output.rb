require 'logging'
require 'logsly/base_output'

module Logsly
  class StdoutOutput < BaseOutput
    def to_appender
      if @appender.nil?
        @appender = Logging.appenders.stdout(:layout => self.to_layout)
      end
      @appender
    end
  end
end
