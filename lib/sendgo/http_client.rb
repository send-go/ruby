require "net/http"
require "json"
require "base64"

module Sendgo
  # Sendgo API HTTP 클라이언트.
  class HttpClient
    def initialize(token_manager:, base_url:, api_version:)
      @token_manager = token_manager
      @base_url      = base_url
      @api_version   = api_version
    end

    def post(path, body)
      do_post(path, body, is_retry: false)
    end

    private

    def do_post(path, body, is_retry: false)
      token  = @token_manager.get_token
      url    = "#{@base_url}/api/#{@api_version}/#{path}"
      uri    = URI(url)
      payload = body.to_json

      req = Net::HTTP::Post.new(uri)
      req["Content-Type"]  = "application/json"
      req["Authorization"] = bearer_auth(token)
      req.body = payload

      resp = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                             read_timeout: 15, open_timeout: 10) { |h| h.request(req) }

      resp_body = JSON.parse(resp.body) rescue {}

      unless resp.is_a?(Net::HTTPSuccess)
        error_code = resp_body["code"]
        endpoint   = path.split("/").last
        if !is_retry && @token_manager.should_refresh?(resp.code.to_i, error_code)
          @token_manager.invalidate
          return do_post(path, body, is_retry: true)
        end
        raise SendgoError.from_response(resp.code.to_i, resp_body, endpoint, @api_version)
      end

      resp_body
    end

    def bearer_auth(token)
      return "Bearer #{token}" if @api_version == "v2"
      "Bearer #{Base64.strict_encode64(token)}"
    end
  end
end
