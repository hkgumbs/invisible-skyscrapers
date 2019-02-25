require "pg"
require "twilio-ruby"
require "sequel"
require "sinatra"

require_relative "api"

DB = Sequel.connect ENV.fetch("DATABASE_URL")
DB.extension :pg_json

TWILIO = Twilio::REST::Client.new(
  ENV.fetch("TWILIO_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
TWILIO_NUMBER = ENV.fetch("TWILIO_NUMBER")

def has_keywords?(tweet)
  tweet =~ /shot|shoot/i && tweet =~ /kill|fatal/i
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

def crime_nodes
  <<-SQL
    SELECT
      'CRIME'                     AS type,
      TO_CHAR(date, 'YYYY-MM-DD') AS label,
      TO_JSON(ARRAY_AGG(tweet))   AS tweets
    FROM crime
    GROUP by date;
  SQL
end

def prayer_nodes
  <<-SQL
    SELECT
      'PRAYER'                    AS type,
      TO_CHAR(date, 'YYYY-MM-DD') AS label
    FROM prayer;
  SQL
end

def get_plot_stuff
  {
    "Prayer": DB[last_five_days "prayer"].select_map(:count),
    "Gunshot Fatalities": DB[last_five_days "crime"].select_map(:count),
  }
end

def with_ids(start, query)
  query.to_enum.with_index(start).map { |x,i| x[:id] = i; x }
end

def get_graph_stuff
  crime = with_ids(0, DB[crime_nodes])
  prayer = with_ids(crime.count, DB[prayer_nodes])
  {
    "Nodes": crime + prayer,
    "Edges": prayer.map do |p|
      crime.map { |c| { from: p[:id], to: c[:id] } if p[:label] == c[:label] }.compact
    end
  }
end

post "/incident" do
  Api.authorize! env
  tweet = Api.json(request).fetch "tweet"
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

get "/plot/graph" do
  Api.ok get_graph_stuff
end
