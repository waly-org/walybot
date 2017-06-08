# Walybot

A [telegram bot](https://core.telegram.org/bots/api) that helps to translate messages for the [waly](http://waly.org/#!/home/main) project.

## Setup

First you need to register your bot.

* login to telegram
* start a conversation with [BotFather](https://core.telegram.org/bots#6-botfather)
* send `/newbot` and copy the bot token into your `config/config.exs` file
* send `/setuserpic`, select your bot and then send the `waly_profile.png` in this repo to set the profile picture
* now disable privacy mode by sending `/setprivacy` then selecting the bot and clicking disabled
  * makes it so the bot can see all messages in a group chat automatically
* now setup the commands to give users helpful autocorrect when talking to the bot by sending `/setcommands`, select your bot, then paste in the text below

__WalyBot Commands__

```
addtranslator - *Admin Only* adds a new translator so they are authorized to start receiving messages
listtranslators - *Admin Only* responds with a list of all translators
```
