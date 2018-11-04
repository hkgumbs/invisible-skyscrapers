require "json"

AUTH_SECRET = ENV.fetch("AUTH_SECRET")

before do
  if request.request_method == 'OPTIONS'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST"
    halt 200
  end
end

module Api
  def self.ok
    return {}
  end

  def self.json
    JSON.load(request.body)
  end

  def self.authorize!
    raise unless env["HTTP_AUTHORIZATION"] == AUTH_SECRET
  end
end
