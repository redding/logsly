
module Logsly::Logging182::Config

  # The Configurator class is used to configure the Logsly::Logging182 framework
  # using information found in a block of Ruby code. This block is evaluated
  # in the context of the configurator's DSL.
  #
  class Configurator

    class Error < StandardError; end  # :nodoc:

    # call-seq:
    #    Configurator.process( &block )
    #
    def self.process( &block )
      new.load(&block)
    end

    # call-seq:
    #    load { block }
    #
    # Loads the configuration from the _block_ and configures the Logsly::Logging182
    # gem.
    #
    def load( &block )
      raise Error, "missing configuration block" unless block

      dsl = TopLevelDSL.new
      dsl.instance_eval(&block)

      pre_config dsl.__pre_config
      ::Logsly::Logging182::Logger[:root]  # ensures the log levels are defined
      appenders  dsl.__appenders
      loggers    dsl.__loggers
    end

    # call-seq:
    #    pre_config( config )
    #
    # Configures the logging levels, object format style, and root logging
    # level.
    #
    def pre_config( config )
      if config.nil?
        ::Logsly::Logging182.init unless ::Logsly::Logging182.initialized?
        return
      end

      # define levels
      levels = config[:levels]
      ::Logsly::Logging182.init(levels) unless levels.nil?

      # format as
      format = config[:format_as]
      ::Logsly::Logging182.format_as(format) unless format.nil?

      # backtrace
      value = config[:backtrace]
      ::Logsly::Logging182.backtrace(value) unless value.nil?
    end

    # call-seq:
    #    appenders( ary )
    #
    # Given an array of Appender configurations, this method will iterate
    # over each and create the Appender(s).
    #
    def appenders( ary )
      ary.each {|name, config| appender(name, config)}
    end

    # call-seq:
    #    loggers( ary )
    #
    # Given an array of Logger configurations, this method will iterate over
    # each and create the Logger(s).
    #
    def loggers( ary )
      ary.each do |name, config|
        l = Logsly::Logging182::Logger[name]
        l.level     = config[:level] if config[:level]
        l.additive  = config[:additive] if l.respond_to? :additive=
        l.trace     = config[:trace]
        l.appenders = Array(config[:appenders]).
                            map {|nm| ::Logsly::Logging182::Appenders[nm]}
      end
    end

    # call-seq:
    #    appender( name, config )
    #
    # Creates a new Appender based on the given _config_ options (a hash).
    # The type of Appender created is determined by the 'type' option in the
    # config. The remaining config options are passed to the Appender
    # initializer.
    #
    # The config options can also contain a 'layout' option. This should be
    # another set of options used to create a Layout for this Appender.
    #
    def appender( name, config )
      type = config.delete(:type)
      raise Error, "appender type not given for #{name.inspect}" if type.nil?

      config[:layout] = layout(config[:layout]) if config.has_key? :layout

      clazz = ::Logsly::Logging182::Appenders.const_get type
      clazz.new(name, config)
    rescue NameError
      raise Error, "unknown appender class Logsly::Logging182::Appenders::#{type}"
    end

    # call-seq:
    #    layout( config )
    #
    # Creates a new Layout based on the given _config_ options (a hash).
    # The type of Layout created is determined by the 'type' option in the
    # config. The remaining config options are passed to the Layout
    # initializer.
    #
    def layout( config )
      return ::Logsly::Logging182::Layouts::Basic.new if config.nil?

      type = config.delete(:type)
      raise Error, 'layout type not given' if type.nil?

      clazz = ::Logsly::Logging182::Layouts.const_get type
      clazz.new config
    rescue NameError
      raise Error, "unknown layout class Logsly::Logging182::Layouts::#{type}"
    end

    class DSL
      instance_methods.each do |m|
        undef_method m unless m[%r/^(__|object_id|instance_eval)/]
      end

      def self.process( &block )
        dsl = new
        dsl.instance_eval(&block)
        dsl.__hash
      end

      def __hash
        @hash ||= Hash.new
      end

      def method_missing( method, *args, &block )
        args << DSL.process(&block) if block

        key = method.to_sym
        value = (1 == args.length ? args.first : args)
        __store(key, value)
      end

      def __store( key, value )
        __hash[key] = value
      end
    end

    class TopLevelDSL < DSL
      undef_method :method_missing

      def initialize
        @loggers = []
        @appenders = []
      end

      def pre_config( &block )
        __store(:preconfig, DSL.process(&block))
      end

      def logger( name, &block )
        @loggers << [name, DSL.process(&block)]
      end

      def appender( name, &block )
        @appenders << [name, DSL.process(&block)]
      end

      def __pre_config() __hash[:preconfig]; end
      def __loggers() @loggers; end
      def __appenders() @appenders; end
    end

  end  # class Configurator
end  # module Logsly::Logging182::Config

