# frozen_string_literal: true

require "cgi"

module Sendgo
  # 짧은 URL — 메시지에 넣는 링크를 줄이고 클릭 반응을 집계한다.
  #
  # v2 전용이다.
  #
  # @example
  #   created = client.short_url.create(
  #     target_url: "https://example.com/promotions/summer-sale",
  #     title: "여름 세일 랜딩"
  #   )
  #
  #   # created.dig("data", "shortUrl") 를 문자/알림톡 본문에 넣는다.
  #   stats = client.short_url.stats(created.dig("data", "code"))
  class ShortUrlService
    def initialize(http:)
      @http = http
    end

    # 짧은 URL 을 만든다.
    #
    # 같은 원본 URL 을 다시 줄이면 기존 링크가 그대로 반환된다.
    # 캠페인별로 반응을 분리해 집계하려면 +force_new: true+ 를 쓴다.
    def create(target_url:, title: nil, expires_at: nil, force_new: false)
      body = { targetUrl: target_url, forceNew: force_new }
      body[:title] = title unless title.nil?
      body[:expiresAt] = expires_at unless expires_at.nil?

      @http.post("short-urls", body)
    end

    # 목록 조회.
    def list(from: nil, to: nil, count: nil)
      @http.get("short-urls", { from: from, to: to, count: count })
    end

    # 상세 조회.
    def show(code)
      @http.get("short-urls/#{escape(code)}")
    end

    # 반응 통계. 일별 추이와 디바이스/유입경로/국가별 분해를 반환한다.
    def stats(code, from: nil, to: nil)
      @http.get("short-urls/#{escape(code)}/stats", { from: from, to: to })
    end

    # 리다이렉트를 중지한다. 링크는 삭제되지 않고 누적 통계도 남는다.
    # 이후 그 링크로 들어오면 410 Gone 이 반환된다.
    def deactivate(code)
      @http.delete("short-urls/#{escape(code)}")
    end

    private

    def escape(code)
      CGI.escape(code.to_s)
    end
  end
end
