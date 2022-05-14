# frozen_string_literal: true

class Fetcher::Nextcord < Fetcher::DpyRtfd
  @library = "nextcord"
  @name = "nextcord"
  @url = "https://docs.nextcord.dev"
  @urls = [
    "https://docs.nextcord.dev/en/stable/api.html",
    "https://docs.nextcord.dev/en/stable/ext/commands/api.html",
    "https://docs.nextcord.dev/en/stable/ext/tasks/api.html",
    "https://docs.nextcord.dev/en/stable/ext/application_checks/index.html",
  ]
  @color = "\e[34m"
end
