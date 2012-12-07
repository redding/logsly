require 'syslog'
require 'logsly/base_output'

module Logsly
  class SyslogOutput < BaseOutput

    option :identity, String
    option :log_opts, Integer, :default => (Syslog::LOG_PID | Syslog::LOG_CONS)
    option :facility, Integer, :default => Syslog::LOG_LOCAL0

    def to_appender
      Syslog.close if Syslog.opened?

      if @appender.nil?
        @appender = Logging.appenders.syslog(self.identity, {
          :logopt   => self.log_opts,
          :facility => self.facility,
          :layout   => self.to_layout
        })
      end
      @appender
    end

  end
end
