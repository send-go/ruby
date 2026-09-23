# frozen_string_literal: true

require "cgi"
require "openssl"

module Sendgo
  # 카카오 발신프로필(채널) 관리 — 등록 · 동기화 · 브랜드메시지 타겟팅 신청.
  #
  # v2 전용이며 **기업(Team) 소유 애플리케이션**만 사용할 수 있다.
  #
  # 채널 등록은 두 단계다. 카카오가 인증번호를 채널 관리자 **휴대폰으로 SMS
  # 발송**하므로 완전 무인 자동화는 불가능하다 — 사람이 문자를 받아
  # +create+ 에 넣어야 한다.
  #
  # @example
  #   # 1단계 — 관리자 휴대폰으로 인증번호 발송 (응답에 번호는 없다)
  #   client.kakao_senders.request_token("@my-channel", "01012345678")
  #
  #   # 2단계 — 사람이 받은 인증번호로 발신프로필 생성
  #   created = client.kakao_senders.create(
  #     token: "123456",
  #     yellow_id: "@my-channel",
  #     phone_number: "01012345678",
  #     category_code: "001001"
  #   )
  #
  #   kakao_sender_key = created.dig("data", "sender", "kakaoSenderKey")
  class KakaoSenderService
    RESOURCE = "kakao-senders"

    def initialize(http:)
      @http = http
    end

    # 1단계 — 채널 인증번호 발송.
    #
    # 응답에 인증번호는 들어있지 않다. 카카오가 +phone_number+ 로 SMS 를 보낸다.
    def request_token(yellow_id, phone_number)
      @http.post("#{RESOURCE}/token", { yellowId: yellow_id, phoneNumber: phone_number })
    end

    # 2단계 — 발신프로필 등록.
    #
    # 이미 등록된 채널을 다시 등록해도 오류가 아니다. 카카오가 같은 senderKey 를
    # 돌려주고 서버가 기존 행을 갱신한다.
    def create(token:, yellow_id:, phone_number:, category_code:)
      @http.post(RESOURCE, {
                   token: token,
                   yellowId: yellow_id,
                   phoneNumber: phone_number,
                   categoryCode: category_code
                 })
    end

    # 목록 조회.
    def list
      @http.get(RESOURCE)
    end

    # 상세 조회.
    def show(kakao_sender_key)
      @http.get("#{RESOURCE}/#{CGI.escape(kakao_sender_key)}")
    end

    # 카테고리 조회. 등록 시 +category_code+ 로 넣을 값이다.
    def categories(category_code = nil)
      @http.get("#{RESOURCE}/categories", { categoryCode: category_code })
    end

    # 상태 동기화. 키를 주면 단건, 없으면 팀 전체.
    #
    # 채널이 카카오 쪽에서 차단·휴면되면 발송이 조용히 실패하기 시작한다.
    # 그 사실을 먼저 알 방법은 이 호출뿐이므로 하루 한 번 정도 돌리는 게 좋다.
    def sync(kakao_sender_key = nil)
      path = kakao_sender_key ? "#{RESOURCE}/#{CGI.escape(kakao_sender_key)}/sync" : "#{RESOURCE}/sync"
      @http.post(path, {})
    end

    # 브랜드메시지 M 신청에 필요한 광고성 정보 수신동의 증적자료 업로드.
    # jpg/png, 5MB 이하.
    #
    # @param evidence [Array, IO] +["proof.png", io, "image/png"]+ 또는 열린 파일
    def upload_brand_message_evidence(kakao_sender_key, evidence)
      @http.post_multipart(
        "#{RESOURCE}/#{CGI.escape(kakao_sender_key)}/brand-message/evidence",
        {},
        { evidence: evidence }
      )
    end

    # 브랜드메시지 +M+(마케팅) / +N+(정보성) 사용 신청.
    #
    # 결과는 즉시 확정되지 않는다. 발신프로필의 +brandMessageStatus+ 로 확인한다.
    def apply_brand_message_targeting(kakao_sender_key, target_type)
      @http.post(
        "#{RESOURCE}/#{CGI.escape(kakao_sender_key)}/brand-message/apply",
        { targetType: target_type }
      )
    end
  end

  # 알림톡 템플릿 관리 — 등록 · 수정 · 검수 요청.
  #
  # v2 전용이며 **기업(Team) 소유 애플리케이션**만 사용할 수 있다.
  #
  # 템플릿은 만든 즉시 쓸 수 없다. 카카오 검수를 통과해야 한다.
  #
  #   등록      inspectionStatus=REG   ← 발송 불가
  #   검수 요청  inspectionStatus=REQ   ← 카카오 심사 중
  #   승인      inspectionStatus=APR   ← 여기부터 발송 가능
  #   반려      inspectionStatus=REJ   ← comments 에 사유
  #
  # 검수 결과는 비동기다. 웹훅이 없으므로 +sync+ 로 폴링한다.
  class NoticeTemplateService
    RESOURCE = "notice-templates"

    def initialize(http:)
      @http = http
    end

    # 목록 조회.
    def list(kakao_sender_key: nil, inspection_status: nil, search: nil, count: nil, folder_uuid: nil)
      @http.get(RESOURCE, {
                  kakaoSenderKey: kakao_sender_key,
                  folderUuid: folder_uuid,
                  inspectionStatus: inspection_status,
                  search: search,
                  count: count
                })
    end

    # 상세 조회. 응답의 +data.template.policy+ 에 정책 검토 상태가 들어 있다.
    def show(template_code)
      @http.get(path(template_code))
    end

    # 템플릿 등록.
    #
    # 정책 인자 일곱 개는 sendgo 자체 게이트다. 카카오 심사와 별개이며 조합이
    # 본문과 어긋나면 +POLICY_VALIDATION_FAILED+ 로 거절된다. 확인 플래그 셋은
    # 기본값이 +true+ 지만, **내용을 실제로 검토한 뒤에** 그대로 두어야 한다 —
    # 이 값은 법적 확인의 기록이다.
    #
    # 선택 필드(+templateTitle+, +buttons+ 등)는 +extra+ 로 넘긴다.
    # +image+ 를 주면 이미지 템플릿으로 multipart 전송한다.
    def create(kakao_sender_key:, template_name:, template_content:,
               template_message_type:, template_emphasize_type:, category_code:,
               message_purpose:, legal_basis:, benefit_origin:, expiry_type:,
               opt_in_review_confirmed: true, cta_clear_confirmed: true,
               policy_confirmed: true, image: nil, **extra)
      body = {
        kakaoSenderKey: kakao_sender_key,
        templateName: template_name,
        templateContent: template_content,
        templateMessageType: template_message_type,
        templateEmphasizeType: template_emphasize_type,
        categoryCode: category_code,
        messagePurpose: message_purpose,
        legalBasis: legal_basis,
        benefitOrigin: benefit_origin,
        expiryType: expiry_type,
        optInReviewConfirmed: opt_in_review_confirmed,
        ctaClearConfirmed: cta_clear_confirmed,
        policyConfirmed: policy_confirmed
      }.merge(camelize_keys(extra))

      return @http.post_multipart(RESOURCE, body, { image: image }) if image

      @http.post(RESOURCE, body)
    end

    # 템플릿 수정.
    #
    # 발신프로필과 템플릿 코드는 바꿀 수 없다. 본문·버튼처럼 카카오에 등록된
    # 내용이 바뀌면 검수 상태가 되돌아가므로 재검수를 요청해야 한다.
    def update(template_code, **fields)
      @http.put(path(template_code), camelize_keys(fields))
    end

    # 템플릿 삭제.
    #
    # **카카오는 템플릿 삭제 API 를 제공하지 않는다.** sendgo 목록에서만
    # 지워지고 비즈니스 채널 쪽 템플릿은 남는다. 동기화하면 다시 나타난다.
    def delete(template_code)
      @http.delete(path(template_code))
    end

    # 카카오에서 검수 상태와 반려 사유를 다시 읽어 온다.
    def sync(template_code)
      @http.post("#{path(template_code)}/sync", {})
    end

    # 검수 요청.
    #
    # 첨부가 있으면 +comment+ 는 필수다. 정책 검토를 통과하지 못한 템플릿은
    # +POLICY_REVIEW_REQUIRED+ 로 거절되고 +errors.reasons+ 에 사유가 담긴다.
    def request_inspection(template_code, comment: nil, attachments: nil)
      endpoint = "#{path(template_code)}/inspection"

      if attachments.nil? || attachments.empty?
        body = comment ? { comment: comment } : {}
        return @http.post(endpoint, body)
      end

      @http.post_multipart(endpoint, { comment: comment }, { attachments: attachments })
    end

    # 검수 요청 취소. 아직 심사 중(+REQ+)일 때만 통한다.
    def cancel_inspection(template_code)
      @http.delete("#{path(template_code)}/inspection")
    end

    # 승인 취소. 승인(+APR+)된 템플릿을 되돌린다. 이후에는 발송할 수 없다.
    def cancel_approval(template_code)
      @http.delete("#{path(template_code)}/approval")
    end

    # 휴면 해제. 오래 안 쓴 템플릿이 dormant 로 잠기면 이걸로 깨운다.
    def release(template_code)
      @http.post("#{path(template_code)}/release", {})
    end

    # 템플릿 카테고리 코드 조회.
    def categories(category_code = nil)
      @http.get("#{RESOURCE}/categories", { categoryCode: category_code })
    end

    private

    def path(template_code)
      "#{RESOURCE}/#{CGI.escape(template_code)}"
    end

    def camelize_keys(hash)
      Sendgo.camelize_keys(hash)
    end
  end

  # 브랜드메시지(구 친구톡) 템플릿 관리.
  #
  # v2 전용이며 **기업(Team) 소유 애플리케이션**만 사용할 수 있다.
  # 알림톡 템플릿과 달리 **검수 요청 단계가 없다.**
  #
  # +template_type+ 은 친구톡 표기(FT/FI/FW/FL/FC/FM/FP/FA)를 그대로 쓴다 —
  # 서버가 chatBubbleType 으로 변환한다.
  class BrandTemplateService
    RESOURCE = "brand-templates"

    def initialize(http:)
      @http = http
    end

    # 목록 조회.
    def list(kakao_sender_key: nil, search: nil, count: nil, folder_uuid: nil)
      @http.get(RESOURCE, { folderUuid: folder_uuid, kakaoSenderKey: kakao_sender_key, search: search, count: count })
    end

    # 상세 조회. sendgo 코드(+KFT-...+)와 카카오 브랜드 템플릿 코드 둘 다 받는다.
    def show(template_code)
      @http.get(path(template_code))
    end

    # 템플릿 등록. 선택 필드는 +extra+ 로 넘긴다 (snake_case 자동 변환).
    def create(kakao_sender_key:, template_name:, template_type:, **extra)
      @http.post(RESOURCE, {
                   kakaoSenderKey: kakao_sender_key,
                   templateName: template_name,
                   templateType: template_type
                 }.merge(Sendgo.camelize_keys(extra)))
    end

    # 템플릿 수정. 발신프로필은 바꿀 수 없다.
    def update(template_code, **fields)
      @http.put(path(template_code), Sendgo.camelize_keys(fields))
    end

    # 템플릿 삭제. 알림톡과 달리 카카오 쪽에서도 실제로 삭제된다.
    def delete(template_code)
      @http.delete(path(template_code))
    end

    # 동기화. 카카오 쪽에서 이미 삭제됐으면 로컬에서도 제거하고
    # +data.deleted: true+ 를 반환한다.
    def sync(template_code)
      @http.post("#{path(template_code)}/sync", {})
    end

    # 발신프로필 단위 가져오기 — 카카오 쪽에 이미 있는 템플릿을 들여온다.
    def import(kakao_sender_key)
      @http.post("#{RESOURCE}/import", { kakaoSenderKey: kakao_sender_key })
    end

    private

    def path(template_code)
      "#{RESOURCE}/#{CGI.escape(template_code)}"
    end
  end

  # 발신번호(문자) 등록 · 심사 접수.
  #
  # v2 전용. 카카오와 달리 **개인 계정 애플리케이션도** 쓸 수 있다.
  #
  # 등록하면 곧바로 쓸 수 있는 게 아니라 +PENDING+ 으로 **접수**되고, 운영자
  # 승인 후 +SUCCESS+ 가 된다.
  class SenderRegistrationService
    RESOURCE = "senders"

    # API 로 접수할 수 있는 발신번호 유형 — 전부다.
    REGISTRABLE_TYPES = %w[
      personal_mobile
      personal_other
      team_main
      team_representative_mobile
      team_emp_mobile
      team_other_company
    ].freeze

    # 신분증 사본(+identityDocument+)이 필요한 유형.
    #
    # 콘솔은 PASS 본인인증을 쓰지만 API 는 신분증 사본을 받아 sendgo 운영자가
    # 직접 확인한다. 이 경로로 접수된 건은 자동 승인되지 않는다.
    IDENTITY_DOCUMENT_TYPES = %w[personal_mobile team_representative_mobile team_emp_mobile].freeze

    def initialize(http:)
      @http = http
    end

    # 목록 조회. 심사 상태(+status+)를 여기서 확인한다.
    def list
      @http.get(RESOURCE)
    end

    # 상세 조회.
    def show(sender_key)
      @http.get("#{RESOURCE}/#{CGI.escape(sender_key)}")
    end

    # 계정 종류에 맞는 발신번호 유형과 유형별 필수 서류.
    #
    # 유형별 +identityVerification+(+none+/+document+)과 필요한 서류 목록을 준다.
    def number_types
      @http.get("#{RESOURCE}/number-types")
    end

    # 등록 전 형식·중복 확인.
    #
    # 응답의 +duplicationReasonRequired+ 가 true 면 +create+ 에
    # +duplication_reason+ 을 함께 넣어야 한다.
    def validate(phone_e164, sender_number_type)
      @http.post("#{RESOURCE}/validate", { phoneE164: phone_e164, senderNumberType: sender_number_type })
    end

    # 등록 신청. 서류가 붙으므로 multipart 로 나간다.
    #
    # +files+ 에는 최소한 +csuCertificate+(통신서비스 이용증명원)가 있어야 한다.
    # 휴대폰 계열은 +identityDocument+(신분증 사본)가, +team_other_company+ 는
    # 수임·위임 서류가 더 필요하다 — {#number_types} 로 확인한다.
    def create(sender_alias:, sender_number_type:, phone_e164:, files:, **extra)
      fields = {
        senderAlias: sender_alias,
        senderNumberType: sender_number_type,
        phoneE164: phone_e164
      }.merge(Sendgo.camelize_keys(extra))

      @http.post_multipart(RESOURCE, fields, files)
    end

    # 별칭 변경 / 기본 발신 지정. 번호와 심사 상태는 바꿀 수 없다.
    def update(sender_key, sender_alias:, primary_type: nil)
      body = { senderAlias: sender_alias }
      body[:primaryType] = primary_type unless primary_type.nil?

      @http.patch("#{RESOURCE}/#{CGI.escape(sender_key)}", body)
    end

    # 삭제. 기본 발신번호를 지우면 남은 번호 중 하나가 기본으로 승계된다.
    def delete(sender_key)
      @http.delete("#{RESOURCE}/#{CGI.escape(sender_key)}")
    end
  end

  # 문자(SMS/LMS/MMS) 상용구 템플릿.
  #
  # v2 전용. 카카오 템플릿과 달리 **검수가 없어** 만들면 바로 쓸 수 있고,
  # 기업 계정이 아니어도 된다.
  class MessageTemplateService
    RESOURCE = "message-templates"

    def initialize(http:)
      @http = http
    end

    # 목록 조회.
    def list(message_type: nil, search: nil, count: nil)
      @http.get(RESOURCE, { messageType: message_type, search: search, count: count })
    end

    # 상세 조회.
    def show(template_key)
      @http.get("#{RESOURCE}/#{CGI.escape(template_key)}")
    end

    # 등록. LMS·MMS 는 +message_tran_subject+ 가 필수다.
    def create(message_tran_type:, message_tran_msg:, message_tran_subject: nil, is_favorite: false)
      body = {
        messageTranType: message_tran_type,
        messageTranMsg: message_tran_msg,
        isFavorite: is_favorite
      }
      body[:messageTranSubject] = message_tran_subject unless message_tran_subject.nil?

      @http.post(RESOURCE, body)
    end

    # 수정.
    def update(template_key, **fields)
      @http.put("#{RESOURCE}/#{CGI.escape(template_key)}", Sendgo.camelize_keys(fields))
    end

    # 삭제 (소프트 삭제 — 목록에서만 사라진다).
    def delete(template_key)
      @http.delete("#{RESOURCE}/#{CGI.escape(template_key)}")
    end
  end

  # Ruby 쪽 인자는 snake_case, Sendgo API 는 camelCase 다. 서비스마다 매핑을
  # 손으로 적으면 필드가 늘 때마다 빠뜨리는 곳이 생기므로 한 곳에서 변환한다.
  #
  # +additional_content+ 는 서버가 그대로 받으므로 예외로 둔다.
  KEEP_AS_IS_KEYS = %w[additional_content].freeze

  def self.camelize_keys(hash)
    hash.each_with_object({}) do |(key, value), result|
      name = key.to_s
      camel =
        if KEEP_AS_IS_KEYS.include?(name) || !name.include?("_")
          name
        else
          head, *rest = name.split("_")
          head + rest.map(&:capitalize).join
        end

      result[camel.to_sym] = value
    end
  end
end

module Sendgo
  # 이벤트 웹훅 구독 — 등록·심사 결과를 밀어 받는다. v2 전용.
  #
  # 심사는 비동기라 폴링 말고는 방법이 없었다. 구독해 두면 상태가 바뀔 때마다
  # 도착한다.
  #
  # @example
  #   created = client.webhook.subscribe("https://reseller.example.com/hooks/sendgo")
  #
  #   # 시크릿은 이 응답에서 한 번만 나온다. 즉시 저장한다.
  #   secret = created.dig("data", "secret")
  class WebhookService
    RESOURCE = "webhook"

    # 구독할 수 있는 이벤트.
    EVENTS = %w[
      sender.status_changed
      notice_template.inspection_status_changed
      kakao_sender.status_changed
      kakao_sender.brand_message_status_changed
    ].freeze

    def initialize(http:)
      @http = http
    end

    # 현재 구독 설정. 마지막 전송 결과(+lastStatus+)도 함께 온다.
    def show
      @http.get(RESOURCE)
    end

    # 구독 생성·수정.
    #
    # +secret+ 을 생략하면 서버가 만들어 **이 응답에서 한 번만** 돌려준다.
    # 이미 시크릿이 있는 상태에서 생략하면 기존 값을 유지한다 — URL 만 바꾸는
    # 호출이 서명 키를 날리지 않는다.
    #
    # +events+ 가 nil 이면 전체 구독이다.
    def subscribe(url, secret: nil, events: nil, enabled: true)
      body = { url: url, enabled: enabled }
      body[:secret] = secret unless secret.nil?
      body[:events] = events unless events.nil?

      @http.put(RESOURCE, body)
    end

    # 테스트 이벤트 발송. 구독 목록과 무관하게 도착한다.
    def test
      @http.post("#{RESOURCE}/test", {})
    end

    # 구독 해지.
    def unsubscribe
      @http.delete(RESOURCE)
    end

    # 수신한 웹훅의 서명을 검증한다.
    #
    # +raw_body+ 는 **받은 바이트 그대로**여야 한다. 파싱한 뒤 다시 인코딩한
    # 값으로 계산하면 키 순서나 이스케이프 차이로 검증이 깨진다.
    # Rails 라면 +request.raw_post+ 다.
    def self.verify_signature(raw_body, signature, secret)
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, raw_body)

      ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
    rescue NameError
      # ActiveSupport 가 없는 순수 Ruby 환경 폴백.
      # 길이가 다르면 fixed_length_secure_compare 가 던지므로 먼저 막는다.
      return false unless expected.bytesize == signature.to_s.bytesize

      OpenSSL.fixed_length_secure_compare(expected, signature.to_s)
    end
  end

  # 카카오 이미지 업로드 — 브랜드메시지 템플릿에 넣을 URL 발급.
  #
  # v2 전용, 기업 계정 전용. 브랜드메시지 템플릿의 +imageUrl+ 은 아무 URL 이나
  # 되는 게 아니라 **카카오가 호스팅하는 URL** 이어야 하고, 그 URL 을 얻는
  # 방법이 이 업로드뿐이다.
  #
  # @example
  #   uploaded = File.open("banner.jpg", "rb") do |f|
  #     client.kakao_images.upload("default", ["banner.jpg", f, "image/jpeg"])
  #   end
  #
  #   client.brand_templates.create(
  #     kakao_sender_key: kakao_sender_key,
  #     template_name: "여름 세일 안내",
  #     template_type: "FI",
  #     image_url: uploaded.dig("data", "imageUrl")
  #   )
  class KakaoImageService
    RESOURCE = "kakao-images"

    # 파일 하나를 올리고 URL 하나를 받는 유형.
    SINGLE_TYPES = %w[alimtalk alimtalk_highlight default wide wide_item_list_first].freeze

    # 파일 여러 개를 올리는 유형과 최대 개수.
    MULTI_TYPES = {
      "wide_item_list" => 4,
      "carousel_feed" => 10,
      "carousel_commerce" => 11
    }.freeze

    def initialize(http:)
      @http = http
    end

    # 업로드 가능한 유형과 제약.
    def types
      @http.get("#{RESOURCE}/types")
    end

    # 단일 이미지 업로드. jpg/png, 2MB 이하. +data.imageUrl+ 을 받는다.
    def upload(image_type, image)
      @http.post_multipart(path(image_type), {}, { image: image })
    end

    # 다중 이미지 업로드. 유형별 최대 개수가 다르다.
    def upload_many(image_type, images)
      @http.post_multipart(path(image_type), {}, { images: images })
    end

    private

    def path(image_type)
      "#{RESOURCE}/#{CGI.escape(image_type)}"
    end
  end

  # 수신거부(080) 번호 조회. v2 전용, 조회 전용.
  #
  # 발송 API 가 알아서 제외하지만 **자기 DB 의 수신 상태도 맞춰야** 한다 —
  # 그러지 않으면 매번 보내고 매번 걸러지는 것을 반복하고, 자기 화면에서는
  # 여전히 "수신 동의" 로 보인다.
  class RejectedNumberService
    RESOURCE = "rejected-numbers"

    def initialize(http:)
      @http = http
    end

    # 증분만 가져가려면 +since+ 를 쓴다. 전체를 매번 받으면 번호가 쌓일수록
    # 무거워진다.
    def list(since: nil, search: nil, count: nil)
      @http.get(RESOURCE, { since: since, search: search, count: count })
    end
  end
end

module Sendgo
  # 템플릿 공용 폴더. v2 전용, 기업 계정 전용.
  class TemplateFolderService
    def initialize(http:)
      @http = http
    end

    def list(template_type: nil, kakao_sender_key: nil)
      @http.get("template-folders", { templateType: template_type, kakaoSenderKey: kakao_sender_key })
    end

    def create(name:, parent_uuid: nil)
      @http.post("template-folders", { name: name, parentUuid: parent_uuid })
    end

    # folder_uuid: nil이면 미분류로 이동합니다. 1~100개 코드가 필요합니다.
    def assign(template_type:, kakao_sender_key:, template_codes:, folder_uuid:)
      @http.patch("template-folders/templates", {
        templateType: template_type, kakaoSenderKey: kakao_sender_key,
        templateCodes: template_codes, folderUuid: folder_uuid
      })
    end
  end
end
