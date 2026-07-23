module Sendgo
  # 카카오 알림톡 전송 서비스.
  #
  # @example
  #   client.alimtalk.send(
  #     template_code: "ORDER_CONFIRM_001",
  #     contacts: [{ contact: "01012345678", var1: "ORD-001" }]
  #   )
  class AlimtalkService
    def initialize(http:, kakao_sender_key:, sms_sender_key:)
      @http            = http
      @kakao_sender_key = kakao_sender_key
      @sms_sender_key  = sms_sender_key
    end

    def send(template_code:, contacts:, schedule_type: "DIRECTLY", at: nil,
             replace_sms: "N", sms_subject: nil, sms_content: nil)
      body = {
        at: at, scheduleType: schedule_type, templateCode: template_code,
        replaceSms: replace_sms,
        smsSubject: replace_sms == "Y" ? sms_subject : nil,
        smsContent: replace_sms == "Y" ? sms_content : nil,
        contacts: contacts,
        kakaoSenderKey: @kakao_sender_key,
        senderKey: @sms_sender_key,
      }
      @http.post("notices/send", body)
    end
  end
end
