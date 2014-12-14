require_relative "../trivia"

describe Question do

  attr_accessor :q, :q2

  before :each do
    @q  = Question.new question: "Sexy time?", answer: "sexy"
    @q2 = Question.new question: "Sexy time?", answer: "Sexy"
  end

  it "reveals guesses properly" do
    q.guess?("book").should == false
    q.hint.should == "____"

    q.guess?("some").should == true
    q.hint.should == "s___"

    q.guess?("sexo").should == true
    q.hint.should == "sex_"
    q.answered?.should == false

    q.guess?("sexy").should == true
    q.answered?.should == true
  end

  it "gives next hints" do
    q.hint.should == "____"
    q.next_hint.should.not == "____"
  end

  it "guess is case insensitive" do
    q2.guess?("sexy").should == true
    q2.hint.should == "Sexy"
  end
end