require 'coderay'
require 'pp'
require 'epitools'

#
# Example tokenization:
#
# [
#   ["toggle", :ident], ["(", :operator], 
    
#   [:begin_group, :string], 
#     ["'", :delimiter], ["clue_DJ_6_5", :content], ["'", :delimiter], 
#   [:end_group, :string], 
  
#   [",", :operator], [" ", :space], 
  
#   [:begin_group, :string], 
#     ["'", :delimiter], ["clue_DJ_6_5_stuck", :content], ["'", :delimiter], 
#   [:end_group, :string], 
  
#   [",", :operator], [" ", :space], 

#   [:begin_group, :string], ["'", :delimiter], ["After the physicist who discovered X-rays, it", :content], ["\\'", :char], ["s another name for a doctor who interprets X-rays", :content], ["'", :delimiter], 
#   [:end_group, :string], 

#   [")", :operator]
# ]

CHAR_TRANSLATE = { "\\'" => "'" }

def extract_strings_from_javascript(js)
  toks = CodeRay::Scanners::JavaScript.new.tokenize(js).each_slice(2)
  parse_toks(toks)
  # pp toks.to_a
end

def parse_toks(toks)
  result = []
  current = []
  toks.each do |tok, type|
    if (tok == :begin_group and type == :string) .. (tok == :end_group and type == :string)

      case type
      when :content
        current << tok
      when :char
        current << CHAR_TRANSLATE[tok] || tok
      when :delimiter, :string
        # skip
      else
        puts "Unknown token type: #{type}"
      end

      if tok == :end_group
        result << current.join
        current.clear
      end

    end
  end

  result
end  

if __FILE__ == $0
  ex1 = "toggle('clue_DJ_6_5', 'clue_DJ_6_5_stuck', 'After the physicist who discovered X-rays, it\\'s another name for a doctor who interprets X-rays')"
  ex2 = "toggle('clue_DJ_6_5', 'clue_DJ_6_5_stuck', '<em class=\"correct_response\">a roentgenologist</em><br /><br /><table width=\"100%\"><tr><td class=\"right\">Justin</td></tr></table>')"

  [ex1, ex2].each do |str|
    result = extract_strings_from_javascript(str)
    result.each {|s| puts s}
    # p toks.map { |tok, type| tok if type == :content }.compact
  end
end

