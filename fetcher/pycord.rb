# frozen_string_literal: true

class Fetcher::Pycord < Fetcher::DpyRtfd
  @library = "pycord"
  @name = "pycord"
  @url = "https://docs.pycord.dev"
  @urls = [
    "https://docs.pycord.dev/en/master/api.html",
    "https://docs.pycord.dev/en/master/ext/commands/api.html",
    "https://docs.pycord.dev/en/master/ext/tasks/api.html",
    "https://docs.pycord.dev/en/master/ext/pages/api.html",
    "https://docs.pycord.dev/en/master/ext/bridge/api.html",
  ]
  @color = "\e[34m"
end
