require 'ns-options'
require 'logging'
require 'logsly/settings'

module Logsly

  def self.included(receiver)
    attr_reader :log_type, :level, :outputs, :logger
    receiver.send(:include, LoggerMethods)
  end

  class MixinOpts
    include NsOptions::Proxy

    option :level,   String, :default => 'info'
    option :outputs, Array,  :default => []
  end

  module LoggerMethods

    def initialize(log_type, opts=nil)
      @log_type = log_type.to_s
      MixinOpts.new(opts).tap do |o|
        @level, @outputs = o.level, o.outputs
      end

      unique_name   = "#{self.class.name}-#{@log_type}-#{self.object_id}"
      @logger       = Logging.logger[unique_name]
      @logger.level = @level

      @outputs.each do |output|
        add_appender(Logsly.outputs(output).to_appender(self))
      end
    end

    # delegate all calls to the @logger

    def method_missing(method, *args, &block)
      @logger.send(method, *args, &block)
    end
    def respond_to?(method)
      super || @logger.respond_to?(method)
    end

    def ==(other_logger)
      other_logger.log_type == @log_type &&
      other_logger.level    == @level    &&
      other_logger.outputs  == @outputs
    end

    def inspect
      reference = '0x0%x' % (self.object_id << 1)
      "#<#{self.class}:#{reference} "\
      "@log_type=#{@log_type.inspect} "\
      "@level=#{@level.inspect} "\
      "@outputs=#{@outputs.inspect}"
    end

    private

    def add_appender(appender)
      @logger.add_appenders(appender) if appender && !appender_added?(appender)
    end

    def appender_added?(appender)
      @logger.appenders.detect do |existing|
        existing.kind_of?(appender.class) && existing.name == appender.name
      end
    end

  end

end
