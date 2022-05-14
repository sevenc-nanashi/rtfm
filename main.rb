require "discorb"
require "dotenv"
require "sequel"

Dotenv.load

client = Discorb::Client.new(
  logger: Logger.new(STDOUT),
)
db = Sequel.connect("sqlite://./db/main.sqlite3")

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.slash_group("rtfm", "ドキュメントを検索します") do |group|
  db.select(:name, :id).from(:libraries).each do |library|
    group.slash(library[:id], "#{library[:name]}", {
      "name" => {
        description: "検索する要素の名前。",
        type: :string,
      },
    }) do |interaction, name, type|
      targets = db.select(:id, :full_name, :url).from(:methods).where(library: library[:id]).all +
                db.select(:id, :full_name, :url).from(:classes).where(library: library[:id]).all +
                db.select(:id, :full_name, :url).from(:attributes).where(library: library[:id]).all
      targets.filter! { |target| target[:full_name].downcase.include?(name.downcase) }
      targets.sort_by! { |target| target[:full_name].to_s.length }
      if targets.length > 0
        text = targets[...8].map do |target|
          "[`#{target[:full_name]}`](#{target[:url]})"
        end.join("\n")
        if targets.length > 8
          text += "\n+ #{targets.length - 8} more..."
        end
      else
        text = "Could not find any results."
      end
      interaction.post(embed: Discorb::Embed.new(
                         "Search results for `#{name}` in #{library[:name]}",
                         text,
                         color: Discorb::Color[:blurple],
                       ))
    end
  end
end
client.run ENV["TOKEN"]
