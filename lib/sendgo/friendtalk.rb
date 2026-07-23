module Sendgo
  # 카카오 친구톡 전송 서비스.
  class FriendtalkService
    def initialize(http:, kakao_sender_key:, sms_sender_key:)
      @http            = http
      @kakao_sender_key = kakao_sender_key
      @sms_sender_key  = sms_sender_key
    end

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
