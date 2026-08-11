module Sendgo
  # 카카오 브랜드메시지 전송 서비스.
  #
  # 브랜드메시지는 친구톡의 후속 채널로, 메시지 타입이 친구톡과 1:1 대응된다
  # (FT→BT, FI→BI, FW→BW, FL→BL, FC→BC, FM→BM, FP→BP, FA→BA).
  # +message_type+ 에는 친구톡 코드를 그대로 넘기고, 변환은 서버가 처리한다.
  #
  # 친구톡과 달리 채널 친구가 아닌 수신자에게도 보낼 수 있고(+targeting: "N"+),
  # 수신 동의한 전체 채널 친구에게 동보 발송할 수 있다(+targeting: "F"+).
  #
  # @example 단건 발송 — 채널 친구 대상
  #   client.brand_message.send(
  #     targeting: "M",
  #     message_type: "FL",
  #     friend_template_uuid: "9cd5460b-6458-4edc-9b11-c26d3013c340",
  #     contacts: [{ contact: "01012345678", var1: "29,000원" }]
  #   )
  #
  # @example 동보 발송 — 수신 동의한 전체 채널 친구 (contacts 불필요)
  #   client.brand_message.broadcast(
  #     message_type: "FW",
  #     friend_template_uuid: "9cd5460b-6458-4edc-9b11-c26d3013c340"
  #   )
  class BrandMessageService
    def initialize(http:, kakao_sender_key:, sms_sender_key:)
      @http             = http
      @kakao_sender_key = kakao_sender_key
      @sms_sender_key   = sms_sender_key
    end

    # 브랜드메시지를 전송한다.
    #
    # +targeting+ 이 "M"/"N"/"I" 이면 +contacts+ 가 필요하고 응답 data 에
    # 발송 건수(sentCount)가 담긴다. "F" 는 동보 발송이라 +contacts+ 없이
    # 접수 여부(accepted)만 반환되므로, 그 경우 #broadcast 가 더 명확하다.
    #
    # +list+ 는 캐러셀 리스트(BC/BA)이며 요청에는 그대로 list 로 전송된다.
    def send(friend_template_uuid:, message_type: "FT", targeting: "M",
             contacts: nil, content: nil, schedule_type: "DIRECTLY", at: nil,
             buttons: [], image_url: nil, image_link: nil,
             ad_flag: "Y", adult: "N", push_alarm: "Y", header: nil,
             coupon: nil, item: nil, commerce: nil, list: nil,
             head: nil, tail: nil, video: nil, additional_content: nil,
             friend_group_key: nil, replace_sms: "N",
             sms_subject: nil, sms_content: nil,
             reject_service_id: nil, webhooks: [])
      body = {
        at: at,
        scheduleType: schedule_type,
        targeting: targeting,
        messageType: message_type,
        friendTemplateUuid: friend_template_uuid,
        content: content,
        buttons: buttons,
        imageUrl: image_url,
        imageLink: image_link,
        adFlag: ad_flag,
        adult: adult,
        pushAlarm: push_alarm,
        header: header,
        coupon: coupon,
        item: item,
        commerce: commerce,
        list: list,
        head: head,
        tail: tail,
        video: video,
        additionalContent: additional_content,
        friendGroupKey: friend_group_key,
        replaceSms: replace_sms,
        smsSubject: replace_sms == "Y" ? sms_subject : nil,
        smsContent: replace_sms == "Y" ? sms_content : nil,
        rejectServiceId: reject_service_id,
        webhooks: webhooks,
        kakaoSenderKey: @kakao_sender_key,
        senderKey: @sms_sender_key,
      }

      # 동보는 수신자 목록이 없다. 빈 배열을 보내면 잘못된 요청으로 거절되므로
      # 키 자체를 넣지 않는다.
      body[:contacts] = contacts || [] unless targeting == "F"

      @http.post("brand-messages/send", body)
    end

    # 동보 발송 — 수신 동의한 전체 채널 친구 (+targeting: "F"+).
    #
    # 수신자 목록은 카카오 측에서 확장하므로 +contacts+ 를 넘기지 않는다.
    # 결과는 #campaigns / #campaign 으로 확인한다.
    def broadcast(**kwargs)
      kwargs.delete(:contacts)
      send(**kwargs, targeting: "F")
    end

    # 브랜드메시지 캠페인 목록을 조회한다.
    def campaigns(from: nil, to: nil, count: nil)
      @http.get("brand-messages", { from: from, to: to, count: count })
    end

    # 브랜드메시지 캠페인 상세를 조회한다.
    # +campaign_id+ 는 발송 응답의 campaignId (UUID).
    def campaign(campaign_id)
      @http.get("brand-messages/#{campaign_id}")
    end
  end
end
