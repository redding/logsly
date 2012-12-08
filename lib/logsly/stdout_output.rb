require 'logging'
require 'logsly/base_output'

module Logsly

  class StdoutOutput < BaseOutput
    def to_appender(*args)
      data = BaseOutputData.new(*args, &self.build)
      Logging.appenders.stdout(:layout => self.to_layout(data))
    end
  end

end
