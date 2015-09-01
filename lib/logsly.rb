require 'ns-options'
require 'logging'
require 'logsly/version'
require 'logsly/colors'
require 'logsly/base_output'

module Logsly

  def self.included(receiver)
    receiver.class_eval do
      attr_reader :log_type, :level, :outputs, :logger
      include LoggerMethods
    end
  end

  module Settings
    include NsOptions::Proxy

    option :colors,  ::Hash, :default => ::Hash.new(NullColors.new)
    option :outputs, ::Hash, :default => ::Hash.new(NullOutput.new)
  end

  def self.reset
    Settings.reset
    Logging.reset
  end

  def self.colors(name, &block)
    require 'logsly/colors'
    Settings.colors[name.to_s] = Colors.new(name, &block) if !block.nil?
    Settings.colors[name.to_s]
  end

  def self.stdout(name, &block)
    require 'logsly/stdout_output'
    Settings.outputs[name.to_s] = StdoutOutput.new(&block)
  end

  def self.file(name, &block)
    require 'logsly/file_output'
    Settings.outputs[name.to_s] = FileOutput.new(&block)
  end

  def self.syslog(name, &block)
    require 'logsly/syslog_output'
    Settings.outputs[name.to_s] = SyslogOutput.new(&block)
  end

  def self.outputs(name)
    Settings.outputs[name.to_s]
  end

  module LoggerMethods

    def initialize(log_type, opts_hash=nil)
      opts = NsOptions::Struct.new(opts_hash) do
        option :level,   String, :default => 'info'
        option :outputs, Array,  :default => []
      end
      @log_type, @level, @outputs = log_type.to_s, opts.level, opts.outputs

      unique_name   = "#{self.class.name}-#{@log_type}-#{self.object_id}"
      @logger       = Logging.logger[unique_name]
      @logger.level = @level

      @outputs.each do |output|
        add_appender(Logsly.outputs(output).to_appender(self))
      end
    end

    def mdc(key, value)
      Logging.mdc[key] = value
    end

    def file_path
      @file_path ||= if (appender = get_file_appender)
        appender.name if appender.respond_to?(:name)
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

    def get_file_appender
      @logger.appenders.detect{ |a| a.kind_of?(Logging::Appenders::File) }
    end

  end

end
