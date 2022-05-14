# frozen_string_literal: true

class Fetcher::DiscordPy < Fetcher::DpyRtfd
  @library = "discordpy"
  @name = "discord.py"
  @url = "https://discordpy.readthedocs.io"
  @urls = [
    "https://discordpy.readthedocs.io/en/master/api.html",
    "https://discordpy.readthedocs.io/en/master/interactions/api.html",
    "https://discordpy.readthedocs.io/en/master/ext/commands/api.html",
    "https://discordpy.readthedocs.io/en/master/ext/tasks/api.html",
  ]
  @color = "\e[34m"
end
