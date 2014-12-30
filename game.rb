#
# TODOs:
# ------------------------------------
#
# * Put date on questions (merge script)
# * Question statistics database, to avoid repeats
# * Make sure guess is case-insensitive
# * How should nick stats work?
#

require 'epitools'


class Scores

  def initialize(filename="scores.json")
    @filename = filename
    load!
  end

  def [](nick)
    @winnings[nick]
  end

  def winner!(nick, amount)
    @winnings[nick] += amount.scan(/\d+/).join.to_i
    save!
  end

  def load!
    if File.exists? @filename
      @winnings = JSON.parse(File.read(@filename))
    else
      @winnings = {}
    end

    @winnings.default = 0
  end

  def save!
    File.write(@filename, JSON.pretty_generate(@winnings))
  end

  def top(n=10)
    @winnings.take(n)
  end

  def all
    @winnings.sort_by { |k,v| -v }
  end

end



class Hint

  HIDDEN_CHAR = "."

  attr_accessor :answer, :hint, :total_letters, :revealed

  def initialize(answer)
    @answer         = answer
    @hint           = answer.gsub(/\w/, HIDDEN_CHAR)
    @total_letters  = @hint.scan(HIDDEN_CHAR).size
    @revealed       = 0.0
    @reveal_percent = 0.2
  end

  def letters_left
    total_letters - revealed
  end

  def reveal(percent)
    previously_revealed = @revealed.floor
    @revealed          += @total_letters * percent
    to_reveal           = (@revealed - previously_revealed).round

    # p to_reveal
    # to_reveal = [@total_letters * percent, 1].max
    hidden_char_positions.pick(to_reveal).each do |pos|
      hint[pos] = answer[pos]
    end
  end

  def hidden_char_positions
    @hint.chars.map.with_index.
      select { |c,i| c == HIDDEN_CHAR }.
      map { |c,i| i }
  end

  def total_hints
    1 + (1.0 / @reveal_percent)
  end

  def next_hint
    reveal(@reveal_percent)

    hint
  end

  def guess?(guess)
    guess           = guess.downcase
    downcase_answer = answer.downcase
    result          = nil

    return :correct if guess == downcase_answer

    hint.chars.each_with_index do |h, i|
      if h == "_" and downcase_answer[i] == guess[i]
        hint[i] = answer[i]
        result = :some_letters
      end
    end

    result
  end

  def too_easy?
    letters_left < total_letters * 0.2
  end

  def ==(other)
    hint == other
  end

  def to_s
    hint
  end

end


class Question
  attr_accessor :category, :question, :answer, :hint, :money, :episode, :date

  def initialize(json)
    @category = json["category"] || json[:category]
    @question = json["question"] || json[:question]
    @answer   = json["answer"]   || json[:answer]
    @episode  = json["episode"]  || json[:episode]
    @date     = json["date"]     || json[:date]
    @money    = json["money"]    || json[:money]

    @hint               = Hint.new @answer
  end

  def next_hint
    hint.next_hint
  end

  def guess?(guess)
    hint.guess?(guess)
  end

  def to_s
    "Category: #{category.inspect}, Question: #{question.inspect}, Answer: #{answer.inspect}"
  end

  def total_hints
    hint.total_hints
  end

end




class Game

  attr_accessor :config, :current_round, :scores, :round_length, :game_thread, :current_question

  def initialize(questions_file)
    @questions = Path[questions_file].parse
    @scores = Scores.new
  end

  def start!(&block)
    @game_thread = Thread.new do
      @config = Config.new &block
      main_loop
    end
  end

  def stop!
    if playing?
      puts "stopping game"
      @game_thread.kill
      @game_thread = nil
      @current_round = nil
      @current_question = nil
      output "Game stopped!"
    end
  end

  def next_question!
    output "Okay, skipping that question..."
    @skip_round = true
    game_thread.wakeup
  end

  def main_loop
    output "Game starting! (Drawing from a pool of #{@questions.size} questions)"

    @current_round = 0

    (1..config.rounds).each do |round|
      @round_over       = false
      @skip_round       = false
      @current_round    = round
      @current_question = random_question

      show_question_and_round
      show_hint

      delay = config.round_length / @current_question.total_hints

      loop do
        sleep delay
        break if @round_over or @skip_round

        @current_question.hint.next_hint
        
        if @current_question.hint.too_easy?
          show_lose
          puts
          break
        end

        show_hint
      end

      next if @skip_round

      if @current_round < config.rounds
        show_between_rounds(config.round_delay)
        sleep config.round_delay
      else
        show_game_over
        break
      end
    end
  end

  def guess!(nick, guess)
    if @current_question 
      puts "<#{nick}> guessed: #{guess.inspect}"

      case @current_question.guess? guess 
      when :some_letters
        show_hint
      when :correct
        scores.winner!(nick, @current_question.money)
        show_win(nick)
        @round_over = true
        game_thread.wakeup
      else
        # terrible guess!
      end
    end
  end

  def output(msg)
    config.on_output.call msg
  end

  def show_question_and_round
    output "Round \2#{@current_round}\2! Category: \2#{@current_question.category}\2, for \2#{@current_question.money}\2 (from episode ##{@current_question.episode}, aired #{@current_question.date})"
    output "Question: \2#{@current_question.question}\2"
  end

  def show_lose
    output "Nobody got it! Answer: \2#{@current_question.answer}\2"
  end

  def show_win(nick)
    output "That's right \2#{nick}\2, the answer was \2#{@current_question.answer}\2! You win #{@current_question.money}! (Total winnings: $#{scores[nick]})"
  end

  def show_hint
    output "Hint: \2#{@current_question.hint}\2"
  end

  def show_between_rounds(seconds)
    output "Next round starts in #{seconds} seconds."
  end

  def show_game_over
    output "That's all folks!"
  end

  def playing?
    @game_thread and @game_thread.alive?
  end

  def random_question
    Question.new @questions.pick
  end


  class Config

    def initialize(&block)
      instance_eval &block
    end

    def on_output(&block)
      block ? @output = block : @output
    end

    def self.config_var(name, default_value)
      define_method(name) do |val=nil|
        if val
          instance_variable_set("@#{name}", val)
        else
          instance_variable_get("@#{name}") || default_value
        end
      end
    end

    # These are variables that the user can set
    config_var :rounds, 10
    config_var :round_length, 60
    config_var :round_delay, 5

  end

end


if $0 == __FILE__
  game = Game.new("questions/some.json")
  game.start! do
    # rounds 3
    # round_length 15

    on_output do |msg|
      puts msg
    end
  end

  Thread.new do
    sleep 2
    game.guess! "fakeuser", game.current_question.answer
    sleep 5
    game.stop!
  end.join

end
