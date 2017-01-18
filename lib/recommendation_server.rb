# Server side calling and request handlers.

module RecommendationServer
  require 'net/http'
  require 'json'

  class Server
    def self.post(api, data)
      begin
        uri=URI(SiteSetting.recommendation_server+api)
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        req.body = data.to_json
        res = http.request(req)
        return JSON.parse(res.body)
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        p "Error Occurred"
        return {}
      end
    end
  end

end
