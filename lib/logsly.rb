require 'logger'
require 'much-plugin'
require 'logsly/version'
require 'logsly/logging182'
require 'logsly/colors'
require 'logsly/outputs'

module Logsly
  include MuchPlugin

  DEFAULT_LEVEL = 'info'.freeze

  plugin_included do
    include InstanceMethods

  end

  def self.reset
    @settings = nil
    Logsly::Logging182.reset
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

    attr_reader :log_type, :level, :outputs, :output_loggers

    def initialize(log_type, opts = nil)
      opts ||= {}

      @log_type = log_type.to_s
      @level    = (opts[:level] || opts['level'] || DEFAULT_LEVEL).to_s
      @outputs  = [*(opts[:outputs] || opts['outputs'] || [])].uniq

      @output_loggers = @outputs.inject({}) do |hash, output_name|
        unique_name = "#{self.class.name}-#{@log_type}-#{self.object_id}-#{output_name}"
        logger      = Logsly::Logging182.logger[unique_name]
        output      = Logsly.outputs(output_name)
        output_data = output.data(self)

        # prefer output-specific level; fall back to general level
        logger.level = output_data ? output_data.level : @level
        add_appender(logger, output.to_appender(output_data))

        hash[output_name] = logger
        hash
      end
    end

    def mdc(key, value)
      Logsly::Logging182.mdc[key] = value
    end

    def file_path
      @file_path ||= if (appender = get_file_appender(self.appenders))
        appender.name if appender.respond_to?(:name)
      end
    end

    # delegate all logger level method calls to the output loggers

    ::Logger::Severity.constants.each do |name|
      define_method(name.downcase) do |*args, &block|
        self.output_loggers.each do |_, logger|
          logger.send(name.downcase, *args, &block)
        end
      end
      define_method("#{name.downcase}?") do |*args, &block|
        self.output_loggers.inject(false) do |bool, (_, logger)|
          bool || logger.send("#{name.downcase}?", *args, &block)
        end
      end
    end

    def appenders
      @appenders ||= self.output_loggers.map{ |(_, l)| l.appenders }.flatten
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

    def add_appender(output_logger, appender)
      output_logger.add_appenders(appender) if appender
    end

    def get_file_appender(appenders)
      self.appenders.detect{ |a| a.kind_of?(Logsly::Logging182::Appenders::File) }
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
