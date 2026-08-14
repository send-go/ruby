require_relative "lib/sendgo/version"

Gem::Specification.new do |spec|
  spec.name          = "sendgo"
  spec.version       = Sendgo::VERSION
  spec.authors       = ["Sendgo"]
  spec.email         = ["dev@sendgo.io"]
  spec.summary       = "Sendgo Ruby SDK — 카카오 알림톡/브랜드메시지, SMS/LMS/MMS"
  spec.description   = "Sendgo API를 Ruby에서 간편하게 사용하기 위한 공식 SDK"
  spec.homepage      = "https://sendgo.io"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  # stdlib only (net/http, json, base64)
end
