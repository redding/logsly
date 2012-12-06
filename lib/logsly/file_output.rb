require 'logsly/base_output'

module Logsly
  class FileOutput < BaseOutput

    option :file, String

    def to_appender
      if @appender.nil?
        @appender = Logging.appenders.file(self.file, {
          :layout => self.to_layout
        })
      end
      @appender
    end

  end
end
