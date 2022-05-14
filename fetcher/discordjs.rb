# frozen_string_literal: true
require "http"

class Fetcher::DiscordJs < Fetcher
  @library = "discordjs"
  @name = "discord.js"
  @url = "https://discord.js.org"
  @color = "\e[32m"

  def fetch
    namespace = NamespaceData.new(self.class.library, self.class.name)
    @namespaces << namespace
    json =
      JSON.parse(
        HTTP.get("https://raw.githubusercontent.com/discordjs/docs/main/discord.js/stable.json")
          .body.to_s,
        symbolize_names: true,
      )
    json[:classes].each do |cls|
      cls_data = ClassData.new(
        [namespace.id, cls[:name]].join(SEPARATOR),
        namespace.id,
        cls[:name],
        cls[:name],
        "https://discord.js.org/#/docs/discord.js/stable/class/#{cls[:name]}",
        cls[:description]
      )
      @classes << cls_data
      cls[:props]&.each do |prop|
        @attributes << AttributeData.new(
          [cls_data.id, "instance", prop[:name]].join(SEPARATOR),
          [cls_data.id, "instance"].join(SEPARATOR),
          prop[:name],
          "#{cls[:name]}##{prop[:name]}",
          "https://discord.js.org/#/docs/discord.js/stable/class/#{cls[:name]}?scrollTo=#{prop[:name]}",
          cls[:description],
        )
      end
      cls[:methods]&.each do |prop|
        params = +""
        prop[:params]&.each do |param|
          params << "[" if param[:optional] && !params.include?("[")
          params << "#{param[:name]}, "
        end
        params.sub!(/, $/, "")
        params << "]" if params.include?("[")
        @methods << MethodData.new(
          [cls_data.id, "instance", prop[:name]].join(SEPARATOR),
          [cls_data.id, "instance"].join(SEPARATOR),
          prop[:name],
          "#{cls[:name]}##{prop[:name]}",
          "https://discord.js.org/#/docs/discord.js/stable/class/#{cls[:name]}?scrollTo=#{prop[:name]}",
          params,
          prop[:description],
        )
      end
      #:id, :parent, :name, :full_name, :url, :document
      #:id, :parent, :name, :full_name, :url, :parameters, :document
    end
  end
end
