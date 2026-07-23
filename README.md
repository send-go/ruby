# sendgo

> **Ruby에서 카카오 알림톡, 친구톡, SMS를 가장 쉽게 발송하는 공식 Ruby SDK**

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
| `base_url` | `String` | 선택 | `'https://api.sendgo.io'` | API 기본 URL |

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

## 라이선스

MIT License © 2026 [Sendgo](https://sendgo.io)

---

*키워드: 카카오 알림톡 Ruby, 카카오 친구톡 Rails, SMS 발송 Ruby, 알림톡 Ruby gem, Ruby 카카오 API 연동, Sendgo Ruby SDK, Rails 알림 발송*
