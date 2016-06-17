
module Logsly::Logging182
  module Appenders

    # call-seq:
    #    Appenders[name]
    #
    # Returns the appender instance stored in the appender hash under the
    # key _name_, or +nil+ if no appender has been created using that name.
    #
    def []( name ) @appenders[name] end

    # call-seq:
    #    Appenders[name] = appender
    #
    # Stores the given _appender_ instance in the appender hash under the
    # key _name_.
    #
    def []=( name, value ) @appenders[name] = value end

    # call-seq:
    #    Appenders.remove( name )
    #
    # Removes the appender instance stored in the appender hash under the
    # key _name_.
    #
    def remove( name ) @appenders.delete(name) end

    # call-seq:
    #    each {|appender| block}
    #
    # Yield each appender to the _block_.
    #
    def each( &block )
      @appenders.values.each(&block)
      return nil
    end

    # :stopdoc:
    def reset
      @appenders.values.each {|appender|
        next if appender.nil?
        appender.close
      }
      @appenders.clear
      return nil
    end
    # :startdoc:

    extend self
    @appenders = Hash.new
  end  # Appenders

  require 'logsly/logging182/appenders/buffering'
  require 'logsly/logging182/appenders/io'
  require 'logsly/logging182/appenders/console'
  require 'logsly/logging182/appenders/email'
  require 'logsly/logging182/appenders/file'
  require 'logsly/logging182/appenders/growl'
  require 'logsly/logging182/appenders/rolling_file'
  require 'logsly/logging182/appenders/string_io'
  require 'logsly/logging182/appenders/syslog'
end  # Logsly::Logging182

