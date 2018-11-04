require "pg"
require "twilio-ruby"
require "sequel"
require "sinatra"

require_relative "api"

DB = Sequel.connect ENV.fetch("DATABASE_URL")
TWILIO = Twilio::REST::Client.new(
  ENV.fetch("TWILIO_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
TWILIO_NUMBER = ENV.fetch("TWILIO_NUMBER")

def has_keywords?(tweet)
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

def last_five_days(table)
  <<-SQL
    SELECT count(#{table})
    FROM #{table}
    FULL JOIN (
      SELECT column1 AS date, 0 AS zero FROM (
      VALUES
        (CURRENT_DATE), 
        (CURRENT_DATE + INTERVAL '-1 day'), 
        (CURRENT_DATE + INTERVAL '-2 day'), 
        (CURRENT_DATE + INTERVAL '-3 day'),
        (CURRENT_DATE + INTERVAL '-4 day')
      ) x
    ) last_week ON #{table}.date = last_week.date
    GROUP BY last_week.date
    ORDER BY last_week.date;
  SQL
end

def get_plot_stuff
  {
    "Gunshots": DB[last_five_days "crime"].select_map(:count),
    "Prayer": DB[last_five_days "prayer"].select_map(:count),
  }
end

post "/incident" do
  Api.authorize!
  tweet = Api.json.fetch "tweet"
  new_crime! tweet if has_keywords? tweet
  Api.ok
end

post "/prayer" do
  new_prayer!
  Api.ok
end

get "/plot/last-week" do
  Api.ok get_plot_stuff
end
