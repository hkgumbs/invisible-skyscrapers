require "json"

AUTH_SECRET = ENV.fetch("AUTH_SECRET")

before do
  if request.request_method == 'OPTIONS'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With"
    halt 200
  end
end

module Api
  def self.ok(data = {})
    return data.to_json
  end

  def self.json
    JSON.load(request.body)
  end

  def self.authorize!
    raise unless env["HTTP_AUTHORIZATION"] == AUTH_SECRET
  end
end
