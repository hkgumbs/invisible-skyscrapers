require "json"
require "pg"
require "sequel"
require "sinatra"

DB = Sequel.connect ENV.fetch("DATABASE_URL")

post "/incident" do
  puts params.to_s
end
