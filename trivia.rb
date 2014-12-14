#
# TODOs:
# ------------------------------------
#
# * Put date on questions (merge script)
# * Question statistics database, to avoid repeats
# * Make sure guess is case-insensitive
# * How should user stats work?
#

require 'epitools'

class Question
  attr_accessor :category, :question, :answer, :hint, :episode, :date

  def initialize(json)
    @category = json["category"] || json[:category]
    @question = json["question"] || json[:question]
    @answer   = json["answer"]   || json[:answer]
    @episode  = json["episode"]  || json[:episode]
    @date     = json["date"]     || json[:date]

    @hint     = Hint.new @answer
  end

  def next_hint
    hint.next_hint
  end

  def guess?(guess)
    hint.guess?(guess)
  end

  def answered?
    hint == answer
  end

  def to_s
    "Category: #{category.inspect}, Question: #{question.inspect}, Answer: #{answer.inspect}"
  end
end


class Hint
  attr_accessor :answer, :hint, :total_letters, :revealed

  def initialize(answer)
    @answer        = answer
    @hint          = answer.gsub(/\w/, "_")
    @total_letters = @hint.scan("_").size
    @revealed      = 0
    @first_hint    = true
  end

  def letters_left
    total_letters - revealed
  end

  def reveal(percent)
    to_reveal = [@total_letters * percent, 1].max
    underscore_positions.pick(to_reveal).each do |pos|
      hint[pos] = answer[pos]
    end
    @revealed += to_reveal
  end

  def underscore_positions
    @hint.chars.map.with_index.
      select { |c,i| c == "_" }.
      map { |c,i| i }
  end

  def next_hint
    @first_hint ? @first_hint = false : reveal(0.1)
    hint
  end

  def guess?(guess)
    guess               = guess.downcase
    downcase_answer     = answer.downcase
    player_got_a_letter = false

    hint.chars.each_with_index do |h, i|
      if h == "_" and downcase_answer[i] == guess[i]
        hint[i] = answer[i]
        player_got_a_letter = true
      end
    end

    player_got_a_letter
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




class Trivia

  attr_accessor :config, :current_round

  def initialize(questions_file)
    @questions = Path[questions_file].parse
  end

  def game(&block)
    @config = Config.new &block
    main_loop
  end

  def main_loop
    @current_round = 0

    (1..config.rounds).each do |round|
      @current_round    = round
      @current_question = random_question

      show_question_and_round

      loop do
        if @current_question.hint.too_easy?
          show_lose
          puts
          break
        else
          show_hint
        end        
      end
    end
  end

  def show_question_and_round
    output "Round #{@current_round}! Category: #{@current_question.category} (from episode ##{@current_question.episode}, aired #{@current_question.date})"
    output "Question: #{@current_question.question}"
  end

  def show_lose
    output "Nobody got it!"
    output "Answer: #{@current_question.answer}"
  end

  def show_hint
    output "Hint: #{@current_question.next_hint}"
  end

  def playing?
    @current_round
  end

  def finish!
    @current_round = nil
    @current_question = nil
  end

  def guess(user, guess)
    if @current_question and @current_question.guess? guess
      output(@current.q)
    end
  end

  def output(msg)
    config.on_output.call msg
  end

  def random_question
    # {
    #   "category": "LAKES & RIVERS",
    #   "question": "River mentioned most often in the Bible",
    #   "answer": "the Jordan",
    #   "money": "$100"
    # },
    Question.new @questions.pick
  end


  class Config

    attr_accessor :on_output, :on_input

    def initialize(&block)
      instance_eval &block
    end

    def on_output(&block)
      block_given? ? @output = block : @output
    end

    def on_input(&block)
      block_given? ? @input = block : @input
    end

    def rounds(val=nil)
      val ? @rounds = val : @rounds
    end

  end

end


if $0 == __FILE__
  trivia = Trivia.new("questions/some.json")

  trivia.game do
    rounds 3

    on_output do |msg|
      puts msg
    end

    on_input do |msg|

    end
  end
end
