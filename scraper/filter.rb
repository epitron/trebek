require 'epitools'

all = Path["../all.json"].parse

# remove video/audio daily doubles
drop, keep = all.partition do |h|
  q = h["question"]
  if q =~ /^\(([^\)]+)\)/
    parens = $1
    parens =~ /(video|audio)/i # maybe remove "clue crew"
  else
    false
  end
end

keep.each { |h| h["money"]  }


# generate a unique ID for each question (based on episode/date?)