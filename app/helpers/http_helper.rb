module Fenix::App::HttpHelper
  def external_request(url, data)
    uri = URI.new url
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 10
    http.use_ssl = url.match?(/^https/)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Post.new(url, {"Content-Type" => "application/json"})
    req.body = data
    http.request(req)
  rescue
    nil
  end
end