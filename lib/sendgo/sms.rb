module Sendgo
  # SMS / LMS / MMS 전송 서비스.
  #
  # @example
  #   client.sms.send_sms(content: "인증번호: 123456", contacts: [{ contact: "01012345678" }])
  class SmsService
    def initialize(http:, sms_sender_key:)
      @http          = http
      @sms_sender_key = sms_sender_key
    end

    def send_sms(content:, contacts:, **opts) = send(content: content, contacts: contacts, message_type: "SMS", **opts)
    def send_lms(content:, contacts:, **opts) = send(content: content, contacts: contacts, message_type: "LMS", **opts)
    def send_mms(content:, contacts:, **opts) = send(content: content, contacts: contacts, message_type: "MMS", **opts)

    def send(content:, contacts:, message_type: "SMS", campaign_type: "MESSAGE",
             schedule_type: "DIRECTLY", at: nil, subject: nil, files: [])
      body = {
        campaignType: campaign_type, messageType: message_type,
        scheduleType: schedule_type, at: at,
        subject: subject, content: content,
        files: files, contacts: contacts,
        senderKey: @sms_sender_key,
      }
      @http.post("messages/send", body)
    end
  end
end
