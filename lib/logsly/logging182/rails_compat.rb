
if defined? ActiveSupport

module Logsly::Logging182

  # Rails compatibility module.
  #
  # The ActiveSupport gem adds a few methods to the default Ruby logger, and
  # some Rails extensions expect these methods to exist. Those methods are
  # implemented in this module and included in the Logsly::Logging182::Logger class when
  # the ActiveSupport gem is present.
  #
  module RailsCompat

    # A no-op implementation of the +formatter+ method.
    def formatter; end

    # A no-op implementation of the +silence+ method. Setting of log levels
    # should be done during the Logsly::Logging182 configuration. It is the author's
    # opinion that overriding the log level programmatically is a logical
    # error.
    #
    # Please see https://github.com/TwP/logging/issues/11 for a more detail
    # discussion of the issue.
    #
    def silence( *args )
      yield self
    end

  end  # RailsCompat

  Logger.send :include, RailsCompat

end  # Logsly::Logging182
end  # if defined?

