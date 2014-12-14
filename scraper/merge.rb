require 'epitools'

SOME = 300

# all = Hash.of_arrays
questions = []

Path["json/*.json"].sort_by(&:filename).each do |file|
  p file
  
  if file.filename =~ /\#(\d+), (?:aired|taped) ([\d\-]+)\.json$/
    episode = $1.to_i
    date    = $2
  else
    raise "Couldn't parse #{file.filename.inspect}"
  end

  file.parse.each do |question|
    # all[question["category"]] << question.slice("question", "answer", "money")
    question["category"].upcase!
    question["date"]    = date
    question["episode"] = episode

    questions << question
  end
end

all, some = Path["../questions/all.json"], Path["../questions/some.json"]

all.write  JSON.pretty_generate(questions)
some.write JSON.pretty_generate(questions.pick(SOME))

system("ls -lh #{all} #{some}")
