require 'logging'
require 'logsly/base_output'

module Logsly

  class FileOutput < BaseOutput
    def to_appender(*args)
      data = FileOutputData.new(*args, &self.build)
      Logging.appenders.file(data.path, :layout => self.to_layout(data))
    end
  end

  class FileOutputData < BaseOutputData
    option :path, String
  end

end
