require "json"
require "pg"
require "twilio-ruby"
require "sequel"
require "sinatra"

DB = Sequel.connect ENV.fetch("DATABASE_URL")
AUTH_SECRET = ENV.fetch("AUTH_SECRET")
TWILIO = Twilio::REST::Client.new(
  ENV.fetch("TWILIO_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
TWILIO_NUMBER = ENV.fetch("TWILIO_NUMBER")

def ok
  return {}
end

def json
  JSON.load(request.body)
end

def authorize!
  raise unless env["HTTP_AUTHORIZATION"] == AUTH_SECRET
end

def has_keywords(tweet)
  tweet =~ /shot|shoot/ && tweet =~ /die|dead/
end

def new_crime!
  DB[:crime].insert(tweet: tweet, date: Time.now)
  TWILIO.api.account.messages.create(
    from: TWILIO_NUMBER,
    to: DB[:userinfo].select_map(:pnum).join(","),
    body: "Pray at noticechicago.com!\n\n" + tweet
  )
end

post "/incident" do
  authorize!
  tweet = json.fetch "tweet"
  new_crime! if has_keywords tweet
  ok
end
