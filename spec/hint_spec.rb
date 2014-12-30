require_relative "../game"

describe Hint do

  it "works for normal guesses" do
    hint = Hint.new "answer"
    hint.guess? "answe"
    hint.hint.should == "answe."
  end

  it "should work with quotes around it" do
    hint = Hint.new %{"A thing"}
    hint.guess? %{"A thin}
    hint.hint.should == %{"A thin."}
  end

end
