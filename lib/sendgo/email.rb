require "net/http"
require "json"
require "base64"
require "uri"
module Sendgo
  # 서버 전용 이메일 API. 객체·배열·204(nil)·EML(String)을 보존합니다.
  class EmailService
    def initialize(token_manager: nil, base_url: "https://sendgo.io", api_version: "v2", credential: nil)
      @tokens, @base_url, @api_version, @credential = token_manager, base_url.sub(%r{/$}, ""), api_version, credential
    end
    # 앱 키가 아닌 이메일 전용 credential ID/password입니다.
    def self.with_credentials(id, password, base_url: "https://sendgo.io")
      new(base_url: base_url, credential: Base64.strict_encode64("#{id}:#{password}"))
    end

    private
    def encode(value)
      URI.encode_www_form_component(value.to_s).gsub("+", "%20")
    end
    def request(method, path, body = nil, query = {}, raw = false, retrying = false)
      raise ArgumentError, "이메일 API는 api_version=v2가 필요합니다." unless @api_version == "v2"
      basic = !@credential.nil?
      prefix = basic ? "email-service" : "email"
      uri = URI("#{@base_url}/api/v2/#{prefix}/#{path}")
      uri.query = URI.encode_www_form(query.reject { |_,v| v.nil? }) unless query.empty?
      req = Net::HTTPGenericRequest.new(method, !body.nil?, true, uri.request_uri)
      req["Authorization"] = basic ? "Basic #{@credential}" : "Bearer #{@tokens.get_token}"
      req["Accept"] = "application/json"
      unless body.nil?
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end
      resp = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 60, open_timeout: 10) { |h| h.request(req) }
      ok = resp.is_a?(Net::HTTPSuccess)
      return resp.body.to_s.b if ok && raw
      begin
        data = resp.body.nil? || resp.body.empty? ? nil : JSON.parse(resp.body)
      rescue JSON::ParserError
        raise if ok
        data = {}
      end
      unless ok
        error = data.is_a?(Hash) ? data : {}
        if !retrying && !basic && resp.code.to_i == 401 && @tokens.should_refresh?(401, error["code"])
          @tokens.invalidate
          return request(method, path, body, query, raw, true)
        end
        raise SendgoError.from_response(resp.code.to_i, error, path, "v2")
      end
      data
    end
    public
    # GET /email/account
    def account(query = {})
      request("GET", "account", nil, query, false)
    end
    # POST /email/request
    def request_access(body = {})
      request("POST", "request", body, {}, false)
    end
    # POST /email/credentials
    def create_credential(body = {})
      request("POST", "credentials", body, {}, false)
    end
    # GET /email/credentials
    def credentials(query = {})
      request("GET", "credentials", nil, query, false)
    end
    # DELETE /email/credentials/{id}
    def revoke_credential(id)
      request("DELETE", "credentials/#{encode(id)}", nil, {}, false)
    end
    # GET /email/domains
    def domains(query = {})
      request("GET", "domains", nil, query, false)
    end
    # POST /email/domains
    def register_domain(body = {})
      request("POST", "domains", body, {}, false)
    end
    # POST /email/domains/{id}/verify
    def verify_domain(id, body = {})
      request("POST", "domains/#{encode(id)}/verify", body, {}, false)
    end
    # GET /email/senders
    def senders(query = {})
      request("GET", "senders", nil, query, false)
    end
    # POST /email/senders
    def request_sender(body = {})
      request("POST", "senders", body, {}, false)
    end
    # POST /email/senders/{id}/verify
    def verify_sender(id, body = {})
      request("POST", "senders/#{encode(id)}/verify", body, {}, false)
    end
    # POST /email/recipients/verification
    def request_recipient_verification(body = {})
      request("POST", "recipients/verification", body, {}, false)
    end
    # POST /email/recipients/check
    def check_recipients(body = {})
      request("POST", "recipients/check", body, {}, false)
    end
    # GET /email/address-book
    def address_book(query = {})
      request("GET", "address-book", nil, query, false)
    end
    # GET /email/sender-profiles
    def sender_profiles(query = {})
      request("GET", "sender-profiles", nil, query, false)
    end
    # POST /email/sender-profiles
    def create_sender_profile(body = {})
      request("POST", "sender-profiles", body, {}, false)
    end
    # PATCH /email/sender-profiles/{id}
    def update_sender_profile(id, body = {})
      request("PATCH", "sender-profiles/#{encode(id)}", body, {}, false)
    end
    # DELETE /email/sender-profiles/{id}
    def delete_sender_profile(id)
      request("DELETE", "sender-profiles/#{encode(id)}", nil, {}, false)
    end
    # POST /email/address-book/import
    def import_address_book(body = {})
      request("POST", "address-book/import", body, {}, false)
    end
    # POST /email/address-book/preferences
    def update_address_book_preferences(body = {})
      request("POST", "address-book/preferences", body, {}, false)
    end
    # POST /email/send
    def send(body)
      request("POST", "send", body, {}, false)
    end
    # POST /email/quote
    def quote(body = {})
      request("POST", "quote", body, {}, false)
    end
    # GET /email/messages
    def messages(query = {})
      request("GET", "messages", nil, query, false)
    end
    # GET /email/messages/{id}
    def message(id, query = {})
      request("GET", "messages/#{encode(id)}", nil, query, false)
    end
    # POST /email/messages/{id}/cancel
    def cancel_message(id, body = {})
      request("POST", "messages/#{encode(id)}/cancel", body, {}, false)
    end
    # GET /email/inboxes
    def inboxes(query = {})
      request("GET", "inboxes", nil, query, false)
    end
    # POST /email/inboxes
    def create_inbox(body = {})
      request("POST", "inboxes", body, {}, false)
    end
    # PATCH /email/inboxes/{id}
    def update_inbox(id, body = {})
      request("PATCH", "inboxes/#{encode(id)}", body, {}, false)
    end
    # GET /email/inboxes/{id}/messages
    def inbox_messages(id, query = {})
      request("GET", "inboxes/#{encode(id)}/messages", nil, query, false)
    end
    # GET /email/inboxes/{id}/messages/{messageId}
    def inbox_message(id, message_id, query = {})
      request("GET", "inboxes/#{encode(id)}/messages/#{encode(message_id)}", nil, query, false)
    end
    # GET /email/inboxes/{id}/messages/{messageId}/raw
    def raw_message(id, message_id, query = {})
      request("GET", "inboxes/#{encode(id)}/messages/#{encode(message_id)}/raw", nil, query, true)
    end
    # DELETE /email/inboxes/{id}/messages/{messageId}
    def delete_inbox_message(id, message_id)
      request("DELETE", "inboxes/#{encode(id)}/messages/#{encode(message_id)}", nil, {}, false)
    end
    # GET /email/templates
    def templates(query = {})
      request("GET", "templates", nil, query, false)
    end
    # GET /email/templates/{id}
    def template(id, query = {})
      request("GET", "templates/#{encode(id)}", nil, query, false)
    end
    # POST /email/templates
    def create_template(body = {})
      request("POST", "templates", body, {}, false)
    end
    # PATCH /email/templates/{id}
    def update_template(id, body = {})
      request("PATCH", "templates/#{encode(id)}", body, {}, false)
    end
    # DELETE /email/templates/{id}
    def delete_template(id)
      request("DELETE", "templates/#{encode(id)}", nil, {}, false)
    end
    # GET /email/contacts
    def contacts(query = {})
      request("GET", "contacts", nil, query, false)
    end
    # POST /email/contacts
    def save_contact(body = {})
      request("POST", "contacts", body, {}, false)
    end
    # POST /email/contacts/import
    def import_contacts(body = {})
      request("POST", "contacts/import", body, {}, false)
    end
    # POST /email/contacts/{id}/unsubscribe
    def unsubscribe_contact(id, body = {})
      request("POST", "contacts/#{encode(id)}/unsubscribe", body, {}, false)
    end
    # GET /email/campaigns
    def campaigns(query = {})
      request("GET", "campaigns", nil, query, false)
    end
    # POST /email/campaigns
    def create_campaign(body = {})
      request("POST", "campaigns", body, {}, false)
    end
    # GET /email/campaigns/{id}
    def campaign(id, query = {})
      request("GET", "campaigns/#{encode(id)}", nil, query, false)
    end
    # POST /email/campaigns/{id}/quote
    def quote_campaign(id, body = {})
      request("POST", "campaigns/#{encode(id)}/quote", body, {}, false)
    end
    # POST /email/campaigns/{id}/send
    def send_campaign(id, body = {})
      request("POST", "campaigns/#{encode(id)}/send", body, {}, false)
    end
    # POST /email/campaigns/{id}/cancel
    def cancel_campaign(id, body = {})
      request("POST", "campaigns/#{encode(id)}/cancel", body, {}, false)
    end
    # GET /email/auth
    def auth(query = {})
      request("GET", "auth", nil, query, false)
    end
  end
end
