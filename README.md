# sendgo

> **Ruby에서 카카오 알림톡, 브랜드메시지, SMS를 가장 쉽게 발송하는 공식 Ruby SDK**

[![Gem Version](https://img.shields.io/gem/v/sendgo)](https://rubygems.org/gems/sendgo)
[![Ruby](https://img.shields.io/badge/Ruby-3.1%2B-CC342D?logo=ruby)](https://ruby-lang.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

`sendgo`는 [Sendgo](https://sendgo.io) 알림 API를 위한 공식 Ruby SDK입니다.
**표준 라이브러리만 사용**하며, MonitorMixin 기반 스레드 안전 토큰 관리를 제공합니다.
Rails, Sinatra, Hanami 등 모든 Ruby 환경에서 사용할 수 있습니다.

---

## 설치

```bash
gem install sendgo
```

또는 Gemfile:

```ruby
gem 'sendgo', '~> 1.0'
```

---

## 빠른 시작

```ruby
require 'sendgo'

client = Sendgo::Client.new(
  access_key:       ENV['SENDGO_ACCESS_KEY'],
  secret_key:       ENV['SENDGO_SECRET_KEY'],
  kakao_sender_key: ENV['SENDGO_KAKAO_SENDER_KEY'],
  sms_sender_key:   ENV['SENDGO_SMS_SENDER_KEY'],
  api_version:      'v2'
)

# 알림톡 발송
client.alimtalk.send(
  template_code: 'ORDER_CONFIRM_001',
  contacts: [
    { contact: '01012345678', name: '홍길동', var1: 'ORD-001', var2: '29,000원' }
  ]
)
```

---

## 알림톡 상세 사용법

```ruby
require 'sendgo'

client = Sendgo::Client.new(
  access_key:       ENV['SENDGO_ACCESS_KEY'],
  secret_key:       ENV['SENDGO_SECRET_KEY'],
  kakao_sender_key: ENV['SENDGO_KAKAO_SENDER_KEY'],
  sms_sender_key:   ENV['SENDGO_SMS_SENDER_KEY'],
  api_version:      'v2'
)

# 다건 발송
client.alimtalk.send(
  template_code: 'ORDER_CONFIRM_001',
  contacts: [
    { contact: '01011111111', name: '홍길동', var1: 'ORD-001', var2: '29,000원' },
    { contact: '01022222222', name: '김철수', var1: 'ORD-002', var2: '15,000원' },
    { contact: '01033333333', name: '이영희', var1: 'ORD-003', var2: '52,000원' }
  ]
)

# 예약 발송
client.alimtalk.send(
  template_code:  'PROMO_SUMMER_2026',
  schedule_type:  'SCHEDULED',
  at:             '2026-07-28 09:00:00',
  contacts: [
    { contact: '01012345678', var1: '여름 한정 50% 할인' }
  ]
)

# SMS 자동 대체 발송
client.alimtalk.send(
  template_code: 'DELIVERY_START_001',
  replace_sms:   'Y',
  sms_subject:   '[배송 시작 안내]',
  sms_content:   "주문하신 상품이 출고되었습니다.\n송장번호: \#{var2}",
  contacts: [
    { contact: '01012345678', var1: 'ORD-001', var2: '1234567890' }
  ]
)
```

---

## 친구톡 사용법

> ⚠️ **Deprecated — 친구톡은 카카오 정책에 따라 2025-12-31 종료되었습니다.**
> 2026-01-01 부터 친구톡 발송 요청은 카카오 측에서 **브랜드메시지(자유형)** 로 자동 대체 발송됩니다.
> 호출은 계속 성공하며, 자유 본문 타입(`FT`/`FI`/`FW`)을 개별 수신자에게 보내는 경로는
> 현재 이것뿐이므로 기존 코드를 당장 바꿀 필요는 없습니다.
>
> 다음의 경우에는 **브랜드메시지**를 사용하세요.
> - 템플릿 기반 리치 타입 (`FL`/`FC`/`FM`/`FP`/`FA`)
> - 채널 친구가 **아닌** 수신자 (`targeting` = `N` / `I`)
> - 수신 동의한 전체 채널 친구 동보 (`targeting` = `F`)
>
> 메시지 타입은 1:1 대응되며 변환은 서버가 처리합니다 — `FT`→`BT`, `FI`→`BI`, `FW`→`BW`,
> `FL`→`BL`, `FC`→`BC`, `FM`→`BM`, `FP`→`BP`, `FA`→`BA`.

```ruby
# 텍스트형
client.friendtalk.send(
  content:  '안녕하세요! 7월 한정 특가 이벤트를 확인해보세요.',
  contacts: [{ contact: '01012345678' }]
)

# 이미지형
client.friendtalk.send(
  message_type: 'FI',
  content:      '이번 주 특가 상품을 확인하세요!',
  image_url:    'https://cdn.example.com/banner.jpg',
  image_link:   'https://example.com/event',
  contacts:     [{ contact: '01012345678' }]
)

# 버튼 포함
client.friendtalk.send(
  content:  '7월 쿠폰이 도착했습니다! 지금 바로 사용하세요.',
  buttons:  [{ name: '쿠폰 받기', type: 'WL', link_mo: 'https://example.com/coupon' }],
  contacts: [{ contact: '01012345678' }]
)
```

---

## 브랜드메시지 사용법

브랜드메시지는 친구톡의 후속 채널입니다. 메시지 타입이 친구톡과 1:1 대응되며
(`FT`→`BT`, `FI`→`BI`, `FW`→`BW`, `FL`→`BL`, `FC`→`BC`, `FM`→`BM`, `FP`→`BP`, `FA`→`BA`),
요청에는 **친구톡 코드를 그대로** 넘기고 변환은 서버가 처리합니다.

친구톡과 달리 다음이 가능합니다.

- 채널 친구가 **아닌** 수신자에게 발송 (`targeting: N`)
- 수신 동의한 **전체 채널 친구 동보** 발송 (`targeting: F`, 수신자 목록 불필요)
- 리스트·캐러셀·커머스·동영상 등 **템플릿 기반 리치 메시지**

> v2 전용입니다. 자유 본문 타입(`FT`/`FI`/`FW`)을 개별 수신자에게 보낼 때는 여전히 친구톡 API 를 쓰세요 — 이 엔드포인트는 그 조합에 `NOT_A_BRAND_MESSAGE` 를 반환합니다. 친구톡 요청은 카카오 측에서 브랜드메시지(자유형)로 대체 발송됩니다.

```ruby
# 단건 발송 — 채널 친구 대상
client.brand_message.send(
  targeting: "M",
  message_type: "FL",
  friend_template_uuid: "9cd5460b-6458-4edc-9b11-c26d3013c340",
  contacts: [{ contact: "01012345678", var1: "29,000원" }]
)

# 동보 발송 — 수신 동의한 전체 채널 친구 (contacts 불필요)
client.brand_message.broadcast(
  message_type: "FW",
  friend_template_uuid: "9cd5460b-6458-4edc-9b11-c26d3013c340"
)

# 캠페인 조회
campaigns = client.brand_message.campaigns(from: "2026-08-01", count: 10)
one = client.brand_message.campaign("1f0a6d0e-6b3b-4f0f-9b2f-2f6f6a1b7c11")
```

---

## SMS / LMS / MMS 사용법

```ruby
# SMS (90자 이하)
client.sms.send_sms(
  content:  '[Sendgo] 인증번호: 123456 (5분 이내 입력)',
  contacts: [{ contact: '01012345678' }]
)

# LMS (장문)
client.sms.send_lms(
  subject:  '[중요] 서비스 점검 안내',
  content:  "안녕하세요. 서비스 점검이 예정되어 있습니다.\n■ 일시: 2026-07-25 02:00 ~ 06:00",
  contacts: [{ contact: '01012345678' }]
)

# MMS (이미지 포함)
client.sms.send_mms(
  subject:  '[이벤트] 7월 특가',
  content:  '이번 달 특가 상품을 확인하세요!',
  contacts: [{ contact: '01011111111' }, { contact: '01022222222' }]
)
```

---

## Rails 통합

```ruby
# config/initializers/sendgo.rb
SENDGO_CLIENT = Sendgo::Client.new(
  access_key:       ENV['SENDGO_ACCESS_KEY'],
  secret_key:       ENV['SENDGO_SECRET_KEY'],
  kakao_sender_key: ENV['SENDGO_KAKAO_SENDER_KEY'],
  sms_sender_key:   ENV['SENDGO_SMS_SENDER_KEY'],
  api_version:      'v2'
)

# app/services/notification_service.rb
class NotificationService
  def initialize(client = SENDGO_CLIENT)
    @client = client
  end

  def send_order_confirm(phone:, order_no:, amount:)
    @client.alimtalk.send(
      template_code: 'ORDER_CONFIRM_001',
      contacts:      [{ contact: phone, var1: order_no, var2: amount }]
    )
  end

  def send_verification_code(phone:, code:)
    @client.alimtalk.send(
      template_code: 'VERIFY_CODE_001',
      replace_sms:   'Y',
      sms_content:   "[인증] 인증번호: #{code} (5분 이내 입력)",
      contacts:      [{ contact: phone, var1: code }]
    )
  end
end

# app/models/order.rb
class Order < ApplicationRecord
  after_create :send_confirmation

  private

  def send_confirmation
    NotificationService.new.send_order_confirm(
      phone:    user.phone,
      order_no: number,
      amount:   "#{total.to_i.to_s(:delimited)}원"
    )
  end
end
```

### Sidekiq 비동기 발송

```ruby
# app/workers/alimtalk_worker.rb
class AlimtalkWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  def perform(template_code, contacts)
    SENDGO_CLIENT.alimtalk.send(
      template_code: template_code,
      contacts:      contacts
    )
  rescue Sendgo::Error => e
    logger.error "알림톡 발송 실패: #{e.message} [#{e.error_code}]"
    raise e unless %w[INVALID_TEMPLATE_CODE PAYMENT_REQUIRED].include?(e.error_code)
  end
end

# 사용
AlimtalkWorker.perform_async('ORDER_CONFIRM_001', [
  { 'contact' => '01012345678', 'var1' => 'ORD-001' }
])
```

---

## 예외 처리

```ruby
require 'sendgo'

begin
  client.alimtalk.send(template_code: 'ORDER_CONFIRM_001', contacts: [...])
rescue Sendgo::Error => e
  puts "발송 실패: HTTP #{e.status_code} [#{e.error_code}]"

  case e.error_code
  when 'INVALID_ACCESS_KEY', 'INVALID_SECRET_KEY'
    alert_ops('Sendgo 인증키를 확인하세요.')
  when 'INVALID_TEMPLATE_CODE'
    Rails.logger.warn("존재하지 않는 템플릿: #{e.message}")
  when 'PAYMENT_REQUIRED'
    alert_ops('Sendgo 크레딧이 부족합니다.')
  when 'IP_NOT_ALLOWED'
    alert_ops('허용되지 않은 IP')
  end
end
```

---

## 설정 옵션

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `access_key` | `String` | **필수** | — | Sendgo 액세스 키 |
| `secret_key` | `String` | **필수** | — | Sendgo 시크릿 키 |
| `kakao_sender_key` | `String` | 선택 | `nil` | 카카오 발신프로필 키 |
| `sms_sender_key` | `String` | 선택 | `nil` | SMS 발신자 키 |
| `api_version` | `String` | 선택 | `'v1'` | API 버전 (`v1` \| `v2`) |
| `base_url` | `String` | 선택 | `'https://sendgo.io'` | API 기본 URL |

---

## 관련 패키지

| 언어/프레임워크 | 패키지 | GitHub |
|----------------|--------|--------|
| Spring Boot | `io.sendgo:sendgo-spring` | [spring](https://github.com/send-go/spring) |
| Node.js | `@sendgo/node` | [node](https://github.com/send-go/node) |
| Python | `sendgo-python` | [python](https://github.com/send-go/python) |
| PHP | `sendgo/php` | [php](https://github.com/send-go/php) |
| 전체 목록 | — | [send-go GitHub 조직](https://github.com/send-go) |

---

## 짧은 URL

짧은 URL 은 메시지 본문의 링크를 줄이고, 그 링크가 실제로 눌렸는지 집계합니다.
문자는 바이트 수가 요금과 직결되므로 링크를 줄이면 그만큼 본문을 더 쓸 수 있습니다.

같은 원본 URL 을 다시 줄이면 **기존 링크가 그대로 반환**됩니다. 캠페인별로 반응을
따로 집계하려면 `forceNew` 로 새 코드를 만드세요.

`deactivate` 는 링크를 삭제하지 않고 리다이렉트만 중지합니다. 이미 발송한 메시지의
링크를 무효화할 때 쓰며, 누적 통계는 남고 이후 접속은 `410 Gone` 이 됩니다.

```ruby
# 짧은 URL 생성 (v2 전용)
created = sendgo.short_url.create(
  target_url: "https://example.com/promotions/summer-sale",
  title: "여름 세일 랜딩"
)

code = created.dig("data", "code")
link = created.dig("data", "shortUrl")

# 반응 통계 — 일별 추이 + 디바이스/유입경로/국가별 분해
stats = sendgo.short_url.stats(code, from: "2026-08-01")

sendgo.short_url.list(count: 10)
sendgo.short_url.show(code)
sendgo.short_url.deactivate(code)   # 리다이렉트만 중지, 통계는 남는다
```

`stats` 는 일별 추이(`daily`)와 디바이스(`byDevice`)·유입경로(`byReferer`)·국가(`byCountry`)별
분해를 반환합니다. 일별 추이는 사전 집계 표에서 읽으므로 클릭이 많아도 응답 시간이 일정합니다.

## 관리 API — 채널·템플릿·발신번호 등록 (v2 전용)

발송은 처음부터 API였지만 **등록과 심사는 콘솔에서만** 되던 것들이 있었습니다.
1.3.0 부터 그 작업도 코드로 처리합니다.

| 서비스 | 하는 일 | 계정 |
| --- | --- | --- |
| `client.kakao_senders` | 카카오 채널 인증·등록·동기화, 브랜드메시지 M/N 신청 | 기업 |
| `client.notice_templates` | 알림톡 템플릿 CRUD, 검수 요청·취소, 승인 취소, 휴면 해제 | 기업 |
| `client.brand_templates` | 브랜드메시지(구 친구톡) 템플릿 CRUD, 동기화, 가져오기 | 기업 |
| `client.sender_registration` | 발신번호 등록 신청, 중복 확인, 유형 안내 | 개인·기업 |
| `client.message_templates` | 문자 상용구 템플릿 CRUD | 개인·기업 |
| `client.kakao_images` | 카카오 이미지 업로드 — 템플릿용 URL 발급 | 기업 |
| `client.rejected_numbers` | 수신거부(080) 번호 조회 | 개인·기업 |
| `client.webhook` | 이벤트 웹훅 구독 — 심사 결과 수신 | 개인·기업 |

> **sendgo.io 콘솔에 들어올 일이 없습니다.** 고객의 채널·발신번호·템플릿을
> 여러분 화면만으로 끝까지 처리할 수 있습니다. 휴대폰 발신번호는 콘솔의 PASS
> 본인인증 대신 **신분증 사본(`identityDocument`)을 받아 sendgo 운영자가 대신
> 심사**합니다.
>
> 사람이 개입하는 지점은 **카카오 채널 인증번호 하나**뿐이고, 그마저도
> 여러분 화면에서 입력받으면 됩니다 — 카카오가 관리자 휴대폰으로 직접 보내는
> 확인이라 없앨 수 없습니다.
>
> 심사가 붙는 것들은 **비동기**입니다. 등록 호출이 성공했다는 건 "접수됐다"는
> 뜻이지 "쓸 수 있다"는 뜻이 아닙니다 — 웹훅을 구독해 결과를 받으세요.

인자는 snake_case 로 씁니다 — SDK 가 camelCase 로 변환해 보냅니다.

### 카카오 채널 등록

```ruby
# 1단계 — 카카오가 관리자 휴대폰으로 인증번호를 SMS 발송한다 (응답에 번호는 없다)
client.kakao_senders.request_token("@my-channel", "01012345678")

# 2단계 — 사람이 받은 인증번호로 발신프로필 생성
created = client.kakao_senders.create(
  token: "123456",
  yellow_id: "@my-channel",
  phone_number: "01012345678",
  category_code: "001001"      # categories 로 조회
)

kakao_sender_key = created.dig("data", "sender", "kakaoSenderKey")

client.kakao_senders.categories
client.kakao_senders.list
client.kakao_senders.sync                    # 전체 상태 동기화 (하루 한 번 권장)
client.kakao_senders.sync(kakao_sender_key)  # 단건
```

채널이 카카오 쪽에서 차단되면 발송이 조용히 실패하기 시작합니다. `sync` 를
주기적으로 돌리고 `block: true` 인 채널을 감시하세요.

### 알림톡 템플릿 등록과 검수

```ruby
created = client.notice_templates.create(
  kakao_sender_key: kakao_sender_key,
  template_name: "주문 접수 안내",
  template_content: "\#{name}님, 주문 \#{orderNo}이 접수되었습니다.",
  template_message_type: "BA",       # BA 기본형 / EX 부가정보형 / AD 채널추가형 / MI 복합형
  template_emphasize_type: "NONE",   # NONE / TEXT / ITEM_LIST / IMAGE
  category_code: "001001",

  # sendgo 자체 정책 게이트 — 카카오 심사와 별개다
  message_purpose: "order_delivery",
  legal_basis: "transaction",
  benefit_origin: "none",
  expiry_type: "none",

  # 선택 필드는 그냥 이어서 쓰면 된다 (snake_case → camelCase 자동 변환)
  buttons: [{ name: "주문 조회", linkType: "WL", linkMo: "https://example.com/orders" }]
)

template_code = created.dig("data", "template", "templateCode")

# 검수 요청 — 증빙이 필요하면 파일도 붙인다 (첨부가 있으면 comment 필수)
client.notice_templates.request_inspection(template_code)

File.open("proof.png", "rb") do |f|
  client.notice_templates.request_inspection(
    template_code,
    comment: "주문 확인 화면 첨부",
    attachments: [["proof.png", f, "image/png"]]
  )
end

# 결과는 비동기다. 웹훅이 없으므로 폴링한다
synced = client.notice_templates.sync(template_code)
synced.dig("data", "template", "inspectionStatus")   # REG → REQ → APR / REJ
```

`opt_in_review_confirmed` · `cta_clear_confirmed` · `policy_confirmed` 는 기본값이
`true` 지만, **내용을 실제로 검토한 뒤에** 그대로 두어야 합니다 — 이 값은 법적
확인의 기록입니다.

정책 필드 조합이 본문과 어긋나면 저장 단계에서 `POLICY_VALIDATION_FAILED` 로
막힙니다. 예외의 `errors["reasons"]` 에 사유가 한국어로 담기니 그대로 사용자에게
보여 주면 됩니다. 여기서 걸리는 문안은 **카카오 심사에서도 거의 반려**되므로,
며칠 기다렸다 반려당하는 것보다 즉시 아는 편이 낫습니다.

```ruby
client.notice_templates.list(kakao_sender_key: kakao_sender_key, inspection_status: "APR")
client.notice_templates.show(template_code)
client.notice_templates.update(template_code, template_content: "...")  # 본문이 바뀌면 재검수 필요
client.notice_templates.cancel_inspection(template_code)
client.notice_templates.cancel_approval(template_code)
client.notice_templates.release(template_code)   # 휴면 해제
client.notice_templates.delete(template_code)    # sendgo 목록에서만 삭제된다
client.notice_templates.categories
```

이미지 템플릿은 `image:` 로 파일을 넘기면 multipart 로 나갑니다.

```ruby
File.open("banner.jpg", "rb") do |f|
  client.notice_templates.create(
    kakao_sender_key: kakao_sender_key,
    template_name: "이벤트 안내",
    template_emphasize_type: "IMAGE",
    image: ["banner.jpg", f, "image/jpeg"],
    # ... 나머지 필드 동일
  )
end
```

> **삭제 동작이 채널마다 다릅니다.** 알림톡 템플릿은 카카오에 삭제 API 가 없어
> sendgo 목록에서만 빠지고 동기화하면 되살아납니다. 브랜드메시지 템플릿은
> 카카오 쪽에서도 실제로 삭제됩니다.

### 브랜드메시지 템플릿

```ruby
created = client.brand_templates.create(
  kakao_sender_key: kakao_sender_key,
  template_name: "여름 세일 안내",
  template_type: "FI",              # FT/FI/FW/FL/FC/FM/FP/FA — 서버가 chatBubbleType 으로 변환
  template_content: "여름 세일이 시작되었습니다.",
  image_url: "https://mud-kage.kakao.com/....jpg"
)

# 동보 발송(targeting="F")에는 변수가 없는 템플릿만 쓸 수 있다
created.dig("data", "template", "containsVariables")

client.brand_templates.list(kakao_sender_key: kakao_sender_key)
client.brand_templates.sync(template_code)
client.brand_templates.import(kakao_sender_key)   # 카카오에 있는 템플릿 가져오기
client.brand_templates.delete(template_code)      # 카카오에서도 삭제된다
```

### 발신번호 등록 신청

```ruby
# 계정 종류에 맞는 유형과 유형별 필수 서류
client.sender_registration.number_types

# 형식·중복 미리 확인
check = client.sender_registration.validate("02-1234-5678", "team_main")

File.open("csu.pdf", "rb") do |f|
  created = client.sender_registration.create(
    sender_alias: "고객센터 대표번호",
    sender_number_type: "team_main",   # personal_other / team_main / team_other_company
    phone_e164: "02-1234-5678",
    files: { csuCertificate: ["csu.pdf", f, "application/pdf"] }
    # check.dig("data", "duplicationReasonRequired") 가 true 면 필수
    # duplication_reason: "부서별 분리 운영"
  )

  created.dig("data", "sender", "status")   # PENDING — 운영자 승인 후 SUCCESS
end

client.sender_registration.list
client.sender_registration.update(sender_key, sender_alias: "새 이름")
client.sender_registration.delete(sender_key)
```

**휴대폰 유형도 API 로 접수할 수 있습니다.** 콘솔의 PASS 본인인증 대신
신분증 사본(`identityDocument`)을 첨부하면 sendgo 운영자가 직접 확인합니다.
이 경로로 접수된 건은 응답의 `identityVerificationMethod` 가 `document` 이고
**자동 승인되지 않습니다** — 운영자 확인 전까지 `PENDING` 입니다.

유형별 필수 서류는 `numberTypes()` 응답의 `requiredDocuments` 로 확인하세요.
반려되면 `rejectionReason` 에 사유가 담깁니다.

### 문자 템플릿

```ruby
client.message_templates.create(
  message_tran_type: "LMS",
  message_tran_subject: "주문 안내",   # LMS·MMS 는 필수
  message_tran_msg: "주문이 접수되었습니다."
)

client.message_templates.list(message_type: "LMS")
client.message_templates.update(template_key, message_tran_msg: "...")
client.message_templates.delete(template_key)
```

### 이벤트 웹훅 — 심사 결과를 밀어 받기

```ruby
created = client.webhook.subscribe("https://reseller.example.com/hooks/sendgo")

# 시크릿은 이 응답에서 한 번만 나온다. 즉시 저장한다.
secret = created.dig("data", "secret")

client.webhook.show          # 구독 설정 + 마지막 전송 결과
client.webhook.test          # 배선 확인
client.webhook.unsubscribe
```

받는 쪽에서는 **원본 바이트**로 서명을 검증합니다.

```ruby
# Rails 라면 request.raw_post 가 원본이다. params 를 다시 인코딩하면 안 된다.
raw = request.raw_post

unless Sendgo::WebhookService.verify_signature(raw, request.headers["X-Sendgo-Signature"], secret)
  head :unauthorized and return
end

payload = JSON.parse(raw)
# payload["event"] — sender.status_changed / notice_template.inspection_status_changed / ...
```

이벤트 목록은 `Sendgo::WebhookService::EVENTS` 로 확인할 수 있습니다.

### 카카오 이미지 업로드

브랜드메시지 템플릿의 `imageUrl` 은 **카카오가 호스팅하는 URL** 이어야 합니다.

```ruby
uploaded = File.open("banner.jpg", "rb") do |f|
  client.kakao_images.upload("default", ["banner.jpg", f, "image/jpeg"])
end

client.brand_templates.create(
  kakao_sender_key: kakao_sender_key,
  template_name: "여름 세일 안내",
  template_type: "FI",
  image_url: uploaded.dig("data", "imageUrl")
)

client.kakao_images.upload_many("carousel_feed", slides)
client.kakao_images.types   # 유형별 필드·최대 개수
```

### 수신거부(080) 동기화

```ruby
# 증분만 가져간다. 하루 한 번이면 충분하다.
client.rejected_numbers.list(since: "2026-09-01", count: 500)
```

---

## 변경 사항

### 1.3.0 (2026-09-11)

- **관리 API 추가** — 콘솔에서만 되던 등록·심사를 코드로 처리합니다.
  `client.kakao_senders`(채널 인증·등록·동기화, 브랜드메시지 M/N 신청),
  `client.notice_templates`(알림톡 템플릿 CRUD·검수 요청·승인 취소·휴면 해제),
  `client.brand_templates`(브랜드메시지 템플릿 CRUD·동기화·가져오기),
  `client.sender_registration`(발신번호 등록 신청·중복 확인·유형 안내),
  `client.message_templates`(문자 상용구 템플릿 CRUD).
- `HttpClient` 에 `put`·`patch`·`post_multipart` 를 추가했습니다.
  서류 첨부와 이미지 템플릿은 JSON 으로 보낼 수 없습니다.
- **`request` 가 PUT/PATCH 를 POST 로 보내던 문제를 함께 고쳤습니다.**
  `case method` 의 `else` 분기가 전부 `Net::HTTP::Post` 를 만들고 있어,
  새 메서드를 그냥 얹었다면 405 만 받았을 자리입니다.
- **휴대폰 발신번호도 API 로 접수됩니다.** 콘솔의 PASS 본인인증 대신
  `identityDocument`(신분증 사본)를 첨부하면 sendgo 운영자가 확인합니다.
  이 경로는 자동 승인되지 않고 항상 `PENDING` 으로 시작합니다.
- **이벤트 웹훅** 추가 — 발신번호 승인, 알림톡 검수 결과, 채널 차단,
  브랜드메시지 타겟팅 결과를 구독해 받습니다. 서명은 받은 원본 바이트로
  검증합니다(SDK 에 검증 헬퍼 포함).
- **카카오 이미지 업로드** 추가 — 브랜드메시지 템플릿의 `imageUrl` 은 카카오가
  호스팅하는 URL 이어야 하는데, 그 URL 을 얻는 길이 콘솔에만 있었습니다.
- **수신거부(080) 조회** 추가 — 자기 DB 의 수신 상태를 맞출 수 있습니다.

### 1.2.1 (2026-08-14)

- 레지스트리 목록에 노출되는 패키지 설명에서 친구톡을 브랜드메시지로 교체했습니다.
  npm/PyPI/Packagist/Maven/NuGet/RubyGems 검색 결과에 그대로 찍히는 문자열이라
  종료된 채널을 계속 홍보하고 있었습니다.
- 검색 키워드에 `brand-message` 를 추가했습니다 (`friendtalk` 은 유입 검색어라 유지).

### 1.2.0 (2026-08-14)

- **친구톡 Deprecated 표기** — 친구톡은 카카오 정책에 따라 2025-12-31 종료되었고,
  2026-01-01 부터 발송 요청이 브랜드메시지(자유형)로 자동 대체 발송됩니다.
  관련 API 에 각 언어의 표준 deprecation 표기를 달았습니다.
- 자유 본문 타입(`FT`/`FI`/`FW`)의 개별 발송 경로는 아직 친구톡 API 뿐이라는 점을
  문서에 명시했습니다 — 브랜드메시지 API 는 그 조합에 `NOT_A_BRAND_MESSAGE` 를 반환합니다.
- 브랜드메시지 전환 안내와 메시지 타입 1:1 대응표를 README 에 추가했습니다.

### 1.1.0 (2026-08-11)

- 짧은 URL 추가 — `client.short_url`
- `HttpClient#delete` 추가
- **버그 수정** — `request()` 가 Get/Post 만 만들어 `:delete` 가 조용히 POST 로 나가고 있었다. `Net::HTTP::Delete` 분기 추가.

## 라이선스

MIT License © 2026 [Sendgo](https://sendgo.io)

---

*키워드: 카카오 알림톡 Ruby, 카카오 친구톡 Rails, SMS 발송 Ruby, 알림톡 Ruby gem, Ruby 카카오 API 연동, Sendgo Ruby SDK, Rails 알림 발송*

## 계정·조직·API 키 관리 (1.4.0)

발송용 `accessKey`/`secretKey`가 없는 단계에서 사용하는 **별도 계정 클라이언트**입니다.
콘솔에서 발급받은 에이전트 토큰(`SENDGO_AGENT_TOKEN`)으로 `/api/v2/account`를 호출합니다.
계정 조회에는 `account:read`, 키·허용 IP 변경에는 `keys:write` 권한이 필요합니다.
토큰 만료나 권한 부족(401/403)은 그대로 예외로 반환하며 자동 갱신·재시도하지 않습니다.

조직 선택은 서버에 저장되는 **사용자 계정의 현재 조직**을 바꿉니다. 같은 사용자로
여러 조직의 설정을 동시에 변경하지 마세요. 개인 계정으로 돌아가려면 조직 ID에
`null`(Python `None`, Ruby `nil`, Go `nil`) 또는 `personal`을 전달합니다.
키 발급 응답의 `data.apiKey.secretKey`는 한 번만 반환되므로 서버의 비밀 저장소에 보관하세요.
허용 IP가 하나라도 등록되면 목록 밖의 IP는 차단됩니다.
에이전트 토큰과 키는 브라우저·모바일 앱에 포함하거나 응답·로그에 출력하지 않습니다.

```ruby
account = Sendgo::AccountClient.new(agent_token: ENV.fetch('SENDGO_AGENT_TOKEN'))
result = account.me
account.select_organization('team-uuid')
issued = account.create_api_key({ name: '서버 연동' })
```

지원 메서드: `me`, `organizations`, `select_organization`, `api_keys`, `create_api_key`, `api_key`, `update_api_key`, `delete_api_key`, `issue_token`, `allowed_ips`, `add_allowed_ip`, `delete_allowed_ip`.

키 생성 인자는 `name`, 선택적 `ipAddresses: [{ip, description}]`이며, 허용 IP 추가 인자는 `ip`, 선택적 `description`입니다. 키·IP 식별자는 응답의 `id`(UUID)를 사용합니다.
