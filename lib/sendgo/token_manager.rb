require "net/http"
require "json"
require "base64"
require "monitor"

module Sendgo
  NO_REFRESH_CODES = %w[
    INVALID_AUTH_HEADER INVALID_BASIC_AUTH INVALID_BASIC_AUTH_PAYLOAD
    INVALID_ACCESS_KEY INVALID_SECRET_KEY ACCESS_KEY_NOT_APPROVED
    TEAM_REQUIRED_FOR_KAKAO IP_NOT_ALLOWED INVALID_SENDER_KEY INVALID_KAKAO_SENDER_KEY
  ].freeze

  TOKEN_TTL = 50 * 60 # 50분 (초)

  # 토큰 발급 및 캐시 관리.
  class TokenManager
    include MonitorMixin

    def initialize(base_url:, access_key:, secret_key:, api_version:)
      super()
      @base_url    = base_url
      @access_key  = access_key
      @secret_key  = secret_key
      @api_version = api_version
      @token       = nil
      @expires_at  = Time.at(0)
    end

    def get_token
      synchronize do
        return @token if @token && Time.now < @expires_at
        fetch_token
      end
    end

    def invalidate
      synchronize { @token = nil; @expires_at = Time.at(0) }
    end

    def should_refresh?(status, error_code)
      return false unless [401, 403].include?(status)
      return false if @api_version == "v2" && NO_REFRESH_CODES.include?(error_code)
      true
    end

    private

    def fetch_token
      uri = URI("#{@base_url}/api/#{@api_version}/token")
      credentials = Base64.strict_encode64("#{@access_key}:#{@secret_key}")

      req = Net::HTTP::Post.new(uri)
      req["Content-Type"]  = "application/json"
      req["Authorization"] = "Basic #{credentials}"

      resp = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |h| h.request(req) }
      body = JSON.parse(resp.body) rescue {}

      unless resp.is_a?(Net::HTTPSuccess) && body.dig("data", "token")
        raise SendgoError.from_response(resp.code.to_i, body, "token", @api_version)
      end

      @token      = body["data"]["token"]
      @expires_at = Time.now + TOKEN_TTL
      @token
    end
  end
end
