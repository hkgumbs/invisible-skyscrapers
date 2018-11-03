require "json"
require "pg"
require "sequel"
require "sinatra"

DB = Sequel.connect ENV.fetch("DATABASE_URL")
AUTH_SECRET = ENV.fetch("AUTH_SECRET")

post "/incident" do
  raise unless env["HTTP_AUTHORIZATION"] == AUTH_SECRET
  tweet = JSON.load(request.body).fetch("tweet")
  DB[:crime].insert(tweet: tweet, date: Time.now)
  return {}
end
