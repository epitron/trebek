# Trebek (IRC Trivia Bot)

An IRC Trivia-bot, with an archive of 30 years of Jeopardy questions!

## Installation

This is a Ruby bot, so you'll first need Ruby, which comes with OSX and most Linux distributions. (If it's not installed, you can learn how to install it from http://ruby-lang.org/)

 1. Make sure bundler is installed: `gem install bundler`
 1. Check out the code: `git clone https://github.com/epitron/trebek`
 1. Run `bundle` from inside the directory (`cd trebek; bundle`) to install dependencies
 1. Download the questions from http://epi.ponzo.net/trebek/all.json.gz , uncompress them (ie: `gunzip all.json.gz`), then put `all.json` in `trebek/questions`
 1. Copy `config.yml-sample` to `config.yml`, then edit `config.yml` to configure which servers and channels you want the bot to connect to, as well as its name and nick
 1. Fire it up: `bundle exec ./go`

The bot should now connect to IRC and join all your channels!

## Playing the game

To start a new game of trivia, just type `!start` in the channel.

These commands are available to anyone in the channel:

command    | what it does...
---------- | ------------------------------------------------
!stop      | Stop the current game
!start     | Start the game
!next      | Skip this question and go to the next
!scores    | Show the high scores

## Playing with the bot

The bot has a console based on Pry. It's essentially just a Ruby REPL that lets you poke into the bot's Ruby objects.

Type `ls` to see the objects in the current scope. Each server in the `config.yml` file will have an object that lets you list its channels, and each channel lets you talk as the bot. Neat!

You can termiate the bot by typing `quit`, or get more help on using pry by typing `help`.
