module Sendgo
  # Sendgo Ruby SDK 메인 클라이언트.
  #
  # @example
  #   client = Sendgo::Client.new(
  #     access_key: ENV["SENDGO_ACCESS_KEY"],
  #     secret_key: ENV["SENDGO_SECRET_KEY"],
  #     kakao_sender_key: ENV["SENDGO_KAKAO_KEY"],
  #     sms_sender_key: ENV["SENDGO_SMS_KEY"],
  #     api_version: "v2"
  #   )
  class Client
    attr_reader :alimtalk, :friendtalk, :sms

    def initialize(access_key:, secret_key:, kakao_sender_key: nil, sms_sender_key: nil,
                   api_version: "v1", base_url: "https://sendgo.io")
      raise ArgumentError, "access_key와 secret_key는 필수입니다" if access_key.nil? || secret_key.nil?

      token_manager = TokenManager.new(base_url: base_url, access_key: access_key,
                                       secret_key: secret_key, api_version: api_version)
      http = HttpClient.new(token_manager: token_manager, base_url: base_url, api_version: api_version)

      @alimtalk   = AlimtalkService.new(http: http, kakao_sender_key: kakao_sender_key, sms_sender_key: sms_sender_key)
      @friendtalk = FriendtalkService.new(http: http, kakao_sender_key: kakao_sender_key, sms_sender_key: sms_sender_key)
      @sms        = SmsService.new(http: http, sms_sender_key: sms_sender_key)
    end
  end
end
