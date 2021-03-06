# Logsly

Logsly is a DSL and a mixin to setup and create custom logger objects.  Define your color schemes and log outputs.  Then mixin Logsly to make your logger classes.  Create instances of your loggers specifying outputs for each, then use your loggers to log stuff to those outputs.

## Usage

```ruby

# define a named output for your logger to use
Logsly.stdout('my_stdout')

# define your logger
class MyLogger
  include Logsly
end

# build a logger instance with a name and use it
logger = MyLogger.new(:outputs => ['my_stdout'])
logger.info "whatever"

# build another logger and use it
bg_logger = MyLogger.new('bg', :level => 'debug', :outputs => ['my_stdout'])
bg_logger.debug "something"
```

## Implementation

Logsly creates and delegates to a [Logging logger](https://github.com/TwP/logging/tree/logging-1.8.2).  When you create an instance of your logger class, Logsly sets up and configures Logging for you.

**Note**: [Logging v1.8.2](https://github.com/TwP/logging/tree/logging-1.8.2) is the last version that is Ruby 1.8.7 compatible.  However, that version doesn't work in modern Ruby versions.  Therefore I've taken the source from Logging v1.8.2 and brought it in manually as a submodule under the `Logsly::Logging182` namespace.  I've tweaked the original source to allow properly requiring/referencing it as a submodule and to also make it work in modern Ruby.  All source in the `Logsly::Logging182` namespace is [MIT License Copyright (c) 2012 Tim Pease](https://github.com/TwP/logging/tree/logging-1.8.2#license) and all credit is his.

## Settings

* `log_type`: custom string used to identify the type of the logger
* `level`: the level in use (default: `'info'`)
* `outputs`: list of named outputs to log to (default: `[]`)

## Outputs

### Stdout

```ruby
Logsly.stdout('my_stdout') do |logger|
  level   'info' # (optional) if set, this level will be used instead of the logger's setting
  pattern '[%d %-5l] : %m\n'
  colors  'my_colors' # use the 'my_colors' color scheme
end
```

Define a named stdout output to use with your loggers.  Pass a block to customize it.  The block will be lazy-eval'd when a logger using it is initialized.  The block is passed the logger instance.

### File

```ruby
Logsly.file('my_file') do |logger|
  path "development.log"

  level   'debug' # log debug level when outputting to this file
  pattern '[%d %-5l] : %m\n'
  # don't use a color scheme
end
```

Define a named file output to use with your loggers.  Takes the same parameters as its stdout counterpart.  Specify the path (relative or absolute) to the log file using the `path` method.

### Syslog

```ruby
Logsly.syslog('my_syslog') do |logger|
  identity "my_syslog_logger" # or whatever
  facility Syslog::LOG_LOCAL0 # or whatever (default: `LOG_LOCAL0`)
  log_opts Syslog::LOG_PID    # or whatever (default: `(LOG_PID | LOG_CONS)`)

  # no custom level set, just use the logger's setting
  pattern '%m\n'
  # don't use a color scheme
end
```

Define a named syslog output to use with your loggers.  Takes the same parameters as its stdout counterpart.  Specify the identity and facility using the respective methods.

### Patterns

Each output can define what pattern to format its messages with using the `pattern' method.  See [Logging's patterns](https://github.com/TwP/logging/blob/logging-1.8.2/lib/logging/layouts/pattern.rb) for details.

### Colors

```ruby
Logsly.colors('my_colors') do
  debug :magenta
  info  :cyan
  warn  :yellow
  error :red
  fatal [:white, :on_red]

  date    :blue
  message :white
end
```

Define a named color scheme to use on your outputs.  Essentially creates a [Logging::ColorScheme](https://github.com/TwP/logging/blob/logging-1.8.2/lib/logging/color_scheme.rb) object.  See that file for configuration and details.

## Installation

Add this line to your application's Gemfile:

    gem 'logsly'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logsly

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
