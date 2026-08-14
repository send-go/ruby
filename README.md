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

## 변경 사항

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
