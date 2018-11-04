require "json"

AUTH_SECRET = ENV.fetch("AUTH_SECRET")

before do
  response.headers["Access-Control-Allow-Origin"] = "*"
  response.headers["Access-Control-Allow-Methods"] = "POST"
  response.headers["Access-Control-Allow-Headers"] = "Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With"
  halt 200 if request.request_method == 'OPTIONS'
end

module Api
  def self.ok(data = {})
    return data.to_json
  end

  def self.json
    JSON.load(request.body)
  end

  def self.authorize!(env)
    raise unless env["HTTP_AUTHORIZATION"] == AUTH_SECRET
  end
end
