module Sendgo
  # Sendgo API 호출 실패 시 발생하는 에러.
  class SendgoError < StandardError
    attr_reader :status_code, :error_code, :endpoint, :api_version, :response_body

    def initialize(message, status_code: 0, error_code: nil, endpoint: "", api_version: "", response_body: {})
      super(message)
      @status_code   = status_code
      @error_code    = error_code
      @endpoint      = endpoint
      @api_version   = api_version
      @response_body = response_body
    end

    def self.from_response(status, body, endpoint, api_version)
      error_code = body["code"]
      message    = body["message"] || "Unknown error"
      msg = "HTTP #{status}"
      msg += " [#{error_code}]" if error_code
      msg += " #{message}"
      new(msg, status_code: status, error_code: error_code, endpoint: endpoint,
          api_version: api_version, response_body: body)
    end
  end
end
