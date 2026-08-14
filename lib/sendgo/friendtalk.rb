module Sendgo
  # 카카오 친구톡 전송 서비스.
  #
  # @deprecated 친구톡은 카카오 정책에 따라 2025-12-31 종료되었습니다.
  #   2026-01-01 부터 친구톡 발송 요청은 카카오 측에서 브랜드메시지(자유형)로
  #   자동 대체 발송되므로, 이 서비스를 호출해도 실제로 나가는 것은 브랜드메시지입니다.
  #   신규 연동은 {BrandMessageService} (+client.brand_message+) 를 사용하세요.
  #   다만 자유 본문 타입(FT/FI/FW)을 개별 수신자에게 보내는 경로는 아직 이
  #   서비스뿐입니다 — 브랜드메시지 API 는 그 조합에 NOT_A_BRAND_MESSAGE 를 반환합니다.
  #   메시지 타입은 1:1 대응됩니다 — FT→BT, FI→BI, FW→BW, FL→BL,
  #   FC→BC, FM→BM, FP→BP, FA→BA.
  class FriendtalkService
    def initialize(http:, kakao_sender_key:, sms_sender_key:)
      @http            = http
      @kakao_sender_key = kakao_sender_key
      @sms_sender_key  = sms_sender_key
    end

    # @deprecated 2025-12-31 종료. +client.brand_message.send+ 를 사용하세요.
    def send(content:, contacts:, message_type: "FT", schedule_type: "DIRECTLY",
             at: nil, buttons: [], image_url: nil, image_link: nil,
             ad_flag: "Y", wide: "N", adult: "N", header: nil,
             replace_sms: "N", sms_subject: nil, sms_content: nil)
      body = {
        at: at, scheduleType: schedule_type, messageType: message_type,
        content: content, buttons: buttons, image: nil,
        imageUrl: image_url, imageLink: image_link,
        adFlag: ad_flag, wide: wide, adult: adult, header: header,
        replaceSms: replace_sms,
        smsSubject: replace_sms == "Y" ? sms_subject : nil,
        smsContent: replace_sms == "Y" ? sms_content : nil,
        contacts: contacts,
        kakaoSenderKey: @kakao_sender_key,
        senderKey: @sms_sender_key,
      }
      @http.post("friends/send", body)
    end
  end
end
