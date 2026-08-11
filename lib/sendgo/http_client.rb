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
      request(:post, path, body: body, is_retry: false)
    end

    # GET 요청. 캠페인 조회 엔드포인트에서 사용한다.
    # params 의 nil 값은 제외되어 서버 기본값이 적용된다.
    def get(path, params = {})
      request(:get, path, params: params, is_retry: false)
    end

    # DELETE 요청. 짧은 URL 리다이렉트 중지에서 사용한다.
    def delete(path)
      request(:delete, path, is_retry: false)
    end

    private

    def request(method, path, body: nil, params: nil, is_retry: false)
      token = @token_manager.get_token
      url   = "#{@base_url}/api/#{@api_version}/#{path}"
      uri   = URI(url)

      if params && !params.empty?
        query = params.reject { |_, v| v.nil? }
        uri.query = URI.encode_www_form(query) unless query.empty?
      end

      req =
        case method
        when :get
          Net::HTTP::Get.new(uri)
        when :delete
          # 바디 없는 DELETE. Post 분기로 흘러가면 조용히 POST 로 나간다.
          Net::HTTP::Delete.new(uri)
        else
          Net::HTTP::Post.new(uri).tap do |r|
            r["Content-Type"] = "application/json"
            r.body = body.to_json
          end
        end
      req["Authorization"] = bearer_auth(token)

      resp = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                             read_timeout: 15, open_timeout: 10) { |h| h.request(req) }

      resp_body = JSON.parse(resp.body) rescue {}

      unless resp.is_a?(Net::HTTPSuccess)
        error_code = resp_body["code"]
        endpoint   = path.split("/").last
        if !is_retry && @token_manager.should_refresh?(resp.code.to_i, error_code)
          @token_manager.invalidate
          return request(method, path, body: body, params: params, is_retry: true)
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
