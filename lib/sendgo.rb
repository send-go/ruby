require_relative "sendgo/version"
require_relative "sendgo/error"
require_relative "sendgo/token_manager"
require_relative "sendgo/http_client"
require_relative "sendgo/alimtalk"
require_relative "sendgo/friendtalk"
require_relative "sendgo/sms"
require_relative "sendgo/client"

# Sendgo Ruby SDK — 카카오 알림톡/친구톡, SMS/LMS/MMS
#
# @example
#   client = Sendgo::Client.new(
#     access_key: ENV["SENDGO_ACCESS_KEY"],
#     secret_key: ENV["SENDGO_SECRET_KEY"],
#     kakao_sender_key: ENV["SENDGO_KAKAO_KEY"],
#     sms_sender_key: ENV["SENDGO_SMS_KEY"],
#     api_version: "v2"
#   )
#
#   client.alimtalk.send(
#     template_code: "ORDER_CONFIRM_001",
#     contacts: [{ contact: "01012345678", var1: "ORD-001" }]
#   )
module Sendgo
end
