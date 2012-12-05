require 'ns-options'

module Logsly

  module Settings
    include NsOptions::Proxy

    option :colors,  ::Hash, :default => {}
    option :outputs, ::Hash, :default => {}
  end

  def self.colors(name, &block)
    require 'logsly/colors'
    Settings.colors[name.to_s] = Colors.new(&block) if !block.nil?
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

end
