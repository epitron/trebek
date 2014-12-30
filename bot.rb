########################################################################

require 'cinch'
require 'yaml'
require 'thread'
require 'pp'
require 'ostruct'
require 'pry'

require_relative 'trebek'
# Dir["plugins/*.rb"].each { |plugin| require_relative plugin }

########################################################################

class Cinch::Bot
  def inspect
    "#<Bot #{@name.inspect} on #{config.server}#{" (SSL)" if config.ssl.use}>"
  end
end

class Cinch::Channel
  def inspect
    "#{@name} (#{bot.config.server})"
  end
end

########################################################################

class TheBot

  attr_accessor :config, :bots, :threads

  def self.new_from_config_file(filename)
    config = YAML.load open(filename)
    new(config)
  end

  def initialize(config)
    @config     = config.dup
    connections = config
    defaults    = connections.delete("defaults") || {}
    
    @bots = {}
    connections.each do |connection_name, options|
      options = defaults.merge(options)
      ssl     = options.delete("ssl")

      bot = Cinch::Bot.new do
        # see: http://rubydoc.info/gems/cinch/file/docs/bot_options.md
        configure do |c|
          c.ssl.use = true if ssl

          options.each do |key, val|
            c.send("#{key}=", val)
          end

          c.plugins.plugins = [Trebek]
        end
      end

      Dir.mkdir "logs" unless File.directory? "logs"

      bot.loggers << Cinch::Logger::FormattedLogger.new(File.open("logs/debug.log", "a"))
      bot.loggers.level = :debug
      bot.loggers.first.level  = :log

      @bots[connection_name] = bot

      define_singleton_method(connection_name) { bot }
    end

  end

  def channels
    bots.map { |name, bot| bot.channels }.flatten
  end

  def connect!
    puts "Connecting all bots..."

    @threads = bots.map do |name, bot|
      Thread.new { bot.start }
    end
  end

  def cli!
    Pry.config.should_load_rc = false
    Pry.config.should_load_local_rc = false
    
    begin
      require 'awesome_print'
      AwesomePrint.pry!
    rescue
    end

    self.pry
  end

end

########################################################################

if __FILE__ == $0

  thebot = TheBot.new_from_config_file "config.yml"

  thebot.connect!
  thebot.cli!

end