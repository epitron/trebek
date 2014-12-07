require 'epitools'

out = Path["all.json"]
out.rm if out.exists?

all = Hash.of_arrays

Path["*.json"].sort_by(&:filename).each do |file|
  p file
  file.parse.each do |question|
    all[question["category"]] << question.slice("question", "answer", "money")
  end
end

out << JSON.pretty_generate(all)

system("ls -lh #{out}")
