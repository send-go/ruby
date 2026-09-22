require "net/http"
require "json"
require "uri"
require_relative "error"

module Sendgo
  # 서버 전용 계정 API. 에이전트 토큰은 자동 갱신하지 않는다.
  class AccountClient
    def initialize(agent_token:, base_url: "https://sendgo.io")
      raise ArgumentError, "Sendgo: agent_token은 필수입니다." if agent_token.to_s.strip.empty?
      @agent_token = agent_token
      @base_url = base_url.sub(%r{/+$}, "")
    end

    # 계정 상태와 다음 단계 조회.
    def me()
      request("GET", "")
    end

    # 조직 목록 조회.
    def organizations()
      request("GET", "organizations")
    end

    # 조직 선택. null은 개인 계정.
    def select_organization(organization_id)
      request("POST", "organizations/select", {'organizationId' => organization_id})
    end

    # 현재 조직의 API 키 목록.
    def api_keys()
      request("GET", "api-keys")
    end

    # API 키 발급. secretKey는 이 응답에서만 반환.
    def create_api_key(params)
      request("POST", "api-keys", params)
    end

    # API 키 상세 조회.
    def api_key(api_key_id)
      request("GET", "api-keys/#{segment(api_key_id)}")
    end

    # API 키 이름 변경.
    def update_api_key(api_key_id, name)
      request("PATCH", "api-keys/#{segment(api_key_id)}", {'name' => name})
    end

    # API 키 폐기.
    def delete_api_key(api_key_id)
      request("DELETE", "api-keys/#{segment(api_key_id)}")
    end

    # 승인된 API 키의 발송용 토큰 발급.
    def issue_token(api_key_id)
      request("POST", "api-keys/#{segment(api_key_id)}/token", {})
    end

    # 허용 IP 목록과 호출자 IP 조회.
    def allowed_ips(api_key_id)
      request("GET", "api-keys/#{segment(api_key_id)}/allowed-ips")
    end

    # 허용 IP 추가. ip와 선택적 description 사용.
    def add_allowed_ip(api_key_id, params)
      request("POST", "api-keys/#{segment(api_key_id)}/allowed-ips", params)
    end

    # 허용 IP 삭제.
    def delete_allowed_ip(api_key_id, ip_id)
      request("DELETE", "api-keys/#{segment(api_key_id)}/allowed-ips/#{segment(ip_id)}")
    end

    private

    def segment(value)
      URI.encode_www_form_component(value).gsub("+", "%20")
    end

    def request(method, path, body = nil)
      uri = URI("#{@base_url}/api/v2/account#{path.empty? ? '' : '/' + path}")
      req = Net::HTTP.const_get(method.capitalize).new(uri)
      req["Authorization"] = "Bearer #{@agent_token}"
      req["Accept"] = "application/json"
      unless body.nil?
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 open_timeout: 10, read_timeout: 15) { |http| http.request(req) }
      data = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        {}
      end
      unless response.is_a?(Net::HTTPSuccess)
        raise SendgoError.from_response(response.code.to_i, data, path.empty? ? "account" : path, "v2")
      end
      data
    end
  end
end
