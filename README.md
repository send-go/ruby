# sendgo (Ruby Gem)

> **Sendgo** Ruby SDK — 카카오 알림톡/친구톡, SMS/LMS/MMS
> Ruby 3.1+, Rails, Sinatra에서 사용 가능합니다.

[![Gem Version](https://img.shields.io/gem/v/sendgo)](https://rubygems.org/gems/sendgo)
[![Ruby](https://img.shields.io/badge/Ruby-3.1+-red)](https://ruby-lang.org)

---

## 빠른 시작 (3단계)

### 1단계 — 설치

```ruby
# Gemfile
gem "sendgo"
```
```bash
bundle install
```

### 2단계 — 환경변수 설정

```env
SENDGO_ACCESS_KEY=your_access_key
SENDGO_SECRET_KEY=your_secret_key
SENDGO_KAKAO_SENDER_KEY=your_kakao_key
SENDGO_SMS_SENDER_KEY=your_sms_key
SENDGO_API_VERSION=v2
```

### 3단계 — 알림톡 전송

```ruby
require "sendgo"

client = Sendgo::Client.new(
  access_key:      ENV["SENDGO_ACCESS_KEY"],
  secret_key:      ENV["SENDGO_SECRET_KEY"],
  kakao_sender_key: ENV["SENDGO_KAKAO_SENDER_KEY"],
  sms_sender_key:  ENV["SENDGO_SMS_SENDER_KEY"],
  api_version:     "v2"
)

client.alimtalk.send(
  template_code: "ORDER_CONFIRM_001",
  contacts: [{ contact: "01012345678", name: "홍길동", var1: "ORD-001" }]
)
```

---

## 기능별 사용법

### 알림톡

```ruby
# 다건 발송
client.alimtalk.send(
  template_code: "ORDER_CONFIRM_001",
  contacts: [
    { contact: "01011111111", var1: "ORD-001" },
    { contact: "01022222222", var1: "ORD-002" }
  ]
)

# SMS 대체 발송
client.alimtalk.send(
  template_code: "DELIVERY_001",
  contacts: [{ contact: "01012345678", var1: "ORD-001" }],
  replace_sms: "Y",
  sms_subject: "[배송 안내]",
  sms_content: "상품이 출고되었습니다."
)
```

### SMS / LMS / MMS

```ruby
client.sms.send_sms(content: "인증번호: 123456", contacts: [{ contact: "01012345678" }])
client.sms.send_lms(subject: "[공지]", content: "점검 예정 안내...", contacts: [...])
client.sms.send_mms(content: "이번 주 특가!", contacts: [...])
```

### 친구톡

```ruby
client.friendtalk.send(
  content: "안녕하세요! 봄맞이 30% 할인 이벤트입니다.",
  contacts: [{ contact: "01012345678" }]
)
```

---

## Rails 통합

```ruby
# config/initializers/sendgo.rb
require "sendgo"

SENDGO = Sendgo::Client.new(
  access_key:      Rails.application.credentials.sendgo[:access_key],
  secret_key:      Rails.application.credentials.sendgo[:secret_key],
  kakao_sender_key: Rails.application.credentials.sendgo[:kakao_sender_key],
  api_version:     "v2"
)
```

```ruby
# app/services/notification_service.rb
class NotificationService
  def self.send_order_confirm(phone, order_number)
    SENDGO.alimtalk.send(
      template_code: "ORDER_CONFIRM_001",
      contacts: [{ contact: phone, var1: order_number }]
    )
  rescue Sendgo::SendgoError => e
    Rails.logger.error "알림톡 발송 실패: #{e.message} [#{e.error_code}]"
    raise
  end
end
```

---

## 예외 처리

```ruby
begin
  client.alimtalk.send(...)
rescue Sendgo::SendgoError => e
  puts "status: #{e.status_code}, code: #{e.error_code}"
  case e.error_code
  when "INVALID_TEMPLATE_CODE" then puts "템플릿 코드를 확인하세요."
  when "PAYMENT_REQUIRED"      then puts "크레딧이 부족합니다."
  end
end
```

---

## 라이선스

MIT License © [Sendgo](https://sendgo.io)
