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


class String

  class IndexedChar < Struct.new(:char, :index)
    include Comparable

    alias c char
    alias i index

    def <=>(other)
      other ? c.downcase <=> other.c.downcase : nil
    end

    def inspect
      %{'#{c}'@#{i}}
    end

  end

  def indexed_chars
    each_char.with_index.map {|c,i| IndexedChar.new(c, i) }
  end

  def indexed_word_chars
    indexed_chars.select {|c| c.c =~ /\w/ }
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
    guess_chars             = guess.indexed_word_chars
    answer_chars            = answer.indexed_word_chars
    result                  = nil

    return :correct if guess_chars == answer_chars

    answer_chars.zip(guess_chars) do |answer_char, guess_char|
      if hint[answer_char.i] == HIDDEN_CHAR and answer_char == guess_char
        hint[answer_char.i] = answer_char.c # reveal letter
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

  def question_with_period
    if question =~ /[\.\!\?]$/
      question
    else
      question + "."
    end
  end

end




class Game

  attr_accessor :config, :current_round, :scores, :round_length, :game_thread, :current_question

  def initialize(questions_file)
    @questions = Path[questions_file].parse
    @scores = Scores.new
  end

  def q; @current_question; end

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
    show_skip_question
    @skip_round = true
    game_thread.wakeup
  end

  def main_loop
    show_game_start

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
        # show_between_rounds(config.round_delay)
        sleep config.round_delay
      else
        show_game_over
        break
      end
    end
  end

  def guess!(nick, guess)
    if @current_question 
      case @current_question.guess? guess 
      when :some_letters
        show_hint
      when :correct
        scores.winner!(nick, q.money)
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

  def show_game_start
    output "It's time to play the game! Let's take a look at the board..."
  end

  def show_question_and_round
    output "The category is \2#{q.category}\2 for \2#{q.money}\2 (aired: #{q.date})"
    output "\2#{q.question_with_period}\2"
  end

  def show_lose
    output "Nobody? It's \2#{q.answer}\2.... \2#{q.answer}\2."
  end

  def show_win(nick)
    confirm = ["Yes,", "That's right,", "Correct,", "Good job, it was"].pick
    output "#{confirm} \2#{q.answer}\2. #{q.money} goes to \2#{nick}\2, for a total of $#{scores[nick]}."
  end

  def show_hint
    output "Hint: \2#{q.hint}\2"
  end

  def show_between_rounds(seconds)
    output "Next round starts in #{seconds} seconds."
  end

  def show_skip_question
    taunt = ["I guess that one was too hard.", "Too challenging?", "Nobody?", "Not your cup of tea?"].pick
    move_on = ["Let's move on...", "Let's try another...", "Maybe we can find something a bit more suitable..."].pick
    output "#{taunt} #{move_on}"
  end    

  def show_game_over
    output "And that's the game! Tune in tomorrow."
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
