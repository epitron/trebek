require 'epitools'
require_relative 'js_string_parser'

class Scraper

  attr_accessor :browser

  FAKE_SPACE = " " # not actually a space

  def initialize
    @browser = Browser.new
  end

  def parse(str)
    html = extract_strings_from_javascript(str).last
    Nokogiri::HTML.fragment(html)
  end

  # weird question: "toggle('clue_DJ_1_5', 'clue_DJ_1_5_stuck', '(<a href=\"http://www.j-archive.com/media/2011-07-29_DJ_13.jpg\" target=\"_blank\">Kelly of the Clue Crew shows an image of some butterflies on a monitor.</a>) The <a href=\"http://www.j-archive.com/media/2011-07-29_DJ_13a.jpg\" target=\"_blank\">monarch</a> butterfly tastes bad to predators, so as a form of defense, <a href=\"http://www.j-archive.com/media/2011-07-29_DJ_13b.jpg\" target=\"_blank\">this</a> palatable but smaller butterfly mimics the monarch\\'s coloration and pattern')"

  def scrape_questions(page)
    results = []

    page.search("table.round").each do |table|

      categories = table.at("tr").search("td.category_name").map(&:text)
      # p categories

      rows = table.children.select{|e| e.name == "tr"}

      rows[1..-1].each do |row|
        boxes = row.search("td.clue")

        categories.zip(boxes).each do |category, box|
          money = (box.at(".clue_value") || box.at(".clue_value_daily_double"))
          money = money.text if money

          box.search("div").each do |div|
            question = div["onmouseout"]
            answer   = div["onmouseover"]

            if question and answer
              question = parse(question)
              answer   = parse(answer).css(".correct_response")

              # q = Question.new(question.text, answer.text, category, money)
              q = {category: category, question: question.text, answer: answer.text, money: money}
              results << q
              # p q
            end
          end

        end

      end
    end

    results
  end


  def scrape_seasons
    index_page = browser.get "http://www.j-archive.com/listseasons.php"

    seasons = index_page.search("#content table a").map{|e| index_page.uri + e["href"] }

    seasons.each do |season|
      season_page = browser.get(season.to_s)

      episodes = season_page.search("#content table a").map{|e| [e.text, season_page.uri + e["href"]] }

      episodes.each do |title, episode|
        game_id = episode.params["game_id"]
        next unless game_id

        title = title.gsub(FAKE_SPACE, " ") # remove fake spaces
        json_filename = "json/#{title}.json"

        puts "-"*50
        puts "* #{title}"
        puts "-"*50

        if File.exists? json_filename
          puts "Skipping!"
          next
        else
          episode_page = browser.get(episode.to_s)
          episode.params
          questions = scrape_questions(episode_page)
          File.write(json_filename, JSON.pretty_generate(questions))
          puts "=> #{questions.size} questions written"
          puts
        end
      end

    end
  end

end


if __FILE__ == $0
  scraper = Scraper.new
  scraper.scrape_seasons
end


