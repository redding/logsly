require 'much-plugin'
require 'logging'
require 'logsly/version'
require 'logsly/colors'
require 'logsly/outputs'

module Logsly
  include MuchPlugin

  plugin_included do
    include InstanceMethods

  end

  def self.reset
    @settings = nil
    Logging.reset
  end

  def self.settings
    @settings ||= Settings.new
  end

  def self.colors(name, &block)
    settings.colors[name.to_s] = Colors.new(name, &block) if !block.nil?
    settings.colors[name.to_s]
  end

  def self.stdout(name, &block)
    settings.outputs[name.to_s] = Outputs::Stdout.new(&block)
  end

  def self.file(name, &block)
    settings.outputs[name.to_s] = Outputs::File.new(&block)
  end

  def self.syslog(name, &block)
    settings.outputs[name.to_s] = Outputs::Syslog.new(&block)
  end

  def self.outputs(name)
    settings.outputs[name.to_s]
  end

  module InstanceMethods

    attr_reader :log_type, :level, :outputs, :logger

    def initialize(log_type, opts = nil)
      opts ||= {}

      @log_type = log_type.to_s
      @level    = (opts[:level]  || opts['level']   || 'info').to_s
      @outputs  = opts[:outputs] || opts['outputs'] || []

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

  class Settings
    attr_reader :colors, :outputs

    def initialize
      @colors  = ::Hash.new(NullColors.new)
      @outputs = ::Hash.new(Outputs::Null.new)
    end
  end

end
