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

  it "should properly show only typeable chars" do
    hint = Hint.new("\"h.e. llo (there)\"")
    hint.guess?("hell").should == :some_letters
    hint.to_s.should == "\"h.e. ll. (.....)\""

    hint.guess?("hello there").should == :correct
  end

  it "hint CharsWithIndex works" do
    String::IndexedChar.new("h", 0).should == String::IndexedChar.new("h", 1)

    "hi".indexed_chars.should == [["h",0], ["i",1]].map {|c,i| String::IndexedChar.new c,i }

    #                               01234567890
    "(hi)th.er.e".indexed_word_chars.should == [["h",1], ["i",2], ["t",4], ["h",5], ["e",7], ["r",8], ["e",10]].map {|c,i| String::IndexedChar.new c,i }
    "(hi)th.er.e".indexed_word_chars.should == "hithere".indexed_word_chars
  end

end
