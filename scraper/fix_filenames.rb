require 'epitools'

weird_char = " "

Path["*.json"].each do |f|

  if f.filename[weird_char]
    f.rename! filename: f.filename.gsub(weird_char, " ")
    p fixed: f.filename
  end

end