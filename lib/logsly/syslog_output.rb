require 'syslog'
require 'logging'
require 'logsly/base_output'

module Logsly

  class SyslogOutput < BaseOutput
    def to_appender(*args)
      Syslog.close if Syslog.opened?

      data = SyslogOutputData.new(*args, &self.build)
      Logging.appenders.syslog(data.identity, {
        :logopt   => data.log_opts,
        :facility => data.facility,
        :layout   => self.to_layout(data)
      })
    end
  end

  class SyslogOutputData < BaseOutputData
    option :identity, String
    option :log_opts, Integer, :default => (Syslog::LOG_PID | Syslog::LOG_CONS)
    option :facility, Integer, :default => Syslog::LOG_LOCAL0
  end

end
