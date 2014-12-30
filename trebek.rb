require 'cinch'
require_relative 'game'

class Trebek
  include Cinch::Plugin

  match "stop", method: :stop_game
  match "start", method: :start_game
  match "next", method: :next_question
  match "scores", method: :scores

  listen_to :message

  attr_accessor :game

  def initialize(*args)
    super
    @game = Game.new("questions/some.json")
  end

  def start_game(m)
    if game.playing?
      m.reply "A game is already running! Try !stop."
    else
      game.start! do
        on_output { |msg| m.reply msg }
      end
    end
  end

  def stop_game(m)
    game.stop!
  end

  def next_question(m)
    game.next_question!
  end

  def scores(m)
    score_string = game.scores.top(10).map { |nick, amount| "#{nick}: $#{amount}" }.join(" | ")
    m.reply "[Total winnings] #{score_string}"
  end

  def listen(m)
    # m.message, m.user.nick, m.reply
    game.guess!(m.user.nick, m.message) if game.playing?
  end

end


bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "trebek"
    c.server          = "irc.freenode.org"
    c.channels        = ["#trebek"]
    c.verbose         = true
    c.plugins.plugins = [Trebek]
  end
end


Thread.new { bot.start }

require 'pry'
Pry.config.should_load_rc = false
Pry.config.should_load_local_rc = false

bot.pry
