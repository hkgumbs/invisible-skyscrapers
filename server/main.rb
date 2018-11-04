require "pg"
require "twilio-ruby"
require "sequel"
require "sinatra"

require_relative "api"

DB = Sequel.connect ENV.fetch("DATABASE_URL")
TWILIO = Twilio::REST::Client.new(
  ENV.fetch("TWILIO_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
TWILIO_NUMBER = ENV.fetch("TWILIO_NUMBER")

def has_keywords(tweet)
  tweet =~ /shot|shoot/ && tweet =~ /kill|fatal/
end

def new_crime!(tweet)
  DB[:crime].insert(tweet: tweet, date: Time.now)
  DB[:userinfo].select_map(:pnum).each do |recipient|
    TWILIO.api.account.messages.create(
      from: TWILIO_NUMBER,
      to: recipient,
      body: "Pray at noticechicago.com!\n\n" + tweet
    )
  end
end

def new_prayer!
  DB[:prayer].insert(date: Time.now)
end

post "/incident" do
  Api.authorize!
  tweet = Api.json.fetch "tweet"
  new_crime! tweet if has_keywords tweet
  Api.ok
end

post "/prayer" do
  new_prayer!
  Api.ok
end
