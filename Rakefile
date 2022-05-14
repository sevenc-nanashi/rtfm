require "sequel"
require "sqlite3"
require_relative "console"

db = Sequel.connect("sqlite://./db/main.sqlite3")

namespace :db do
  desc "データベースを初期化します"
  task :init do
    db.create_table! :libraries do
      # -- id -------
      String :id, primary_key: true, unique: true
      # -- data -----
      String :name
      String :url
    end
    db.create_table! :namespaces do
      # -- id -------
      String :id, primary_key: true, unique: true
      # -- key ------
      String :library
      # -- data -----
      String :name
    end
    db.create_table! :classes do
      # -- id -------
      String :id, primary_key: true, unique: true
      # -- key ------
      String :library
      String :parent
      # -- data -----
      String :name
      String :full_name
      String :url
      String :document, text: true
    end
    db.create_table! :methods do
      # -- id -------
      String :id, primary_key: true, unique: true
      # -- key ------
      String :library
      String :parent
      # -- data -----
      String :name
      String :full_name
      String :url
      String :parameters
      String :document, text: true
    end
    db.create_table! :attributes do
      # -- id -------
      String :id, primary_key: true, unique: true
      # -- key ------
      String :library
      String :parent
      # -- data -----
      String :name
      String :full_name
      String :url
      String :document, text: true
    end
  end

  desc "データベースを削除します"
  task :clear do
    db.drop_table :libraries
    db.drop_table :namespaces
    db.drop_table :classes
    db.drop_table :methods
    db.drop_table :attributes
  end

  desc "ドキュメントを読み込みます"
  task :fetch do
    begin
      Rake::Task["db:clear"].invoke
    rescue Sequel::DatabaseError
    end
    Rake::Task["db:init"].invoke

    require_relative "fetcher/base/base"
    require_relative "fetcher/base/dpy_rtfd"
    require_relative "fetcher/base/rubydoc"

    require_relative "fetcher/discordpy"
    require_relative "fetcher/pycord"
    require_relative "fetcher/nextcord"

    require_relative "fetcher/discorb"
    require_relative "fetcher/discordrb"

    require_relative "fetcher/discordjs"

    Fetcher.save_all(db)
  end
end
