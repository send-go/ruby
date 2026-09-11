require "net/http"
require "json"
require "base64"
require "securerandom"

module Sendgo
  # Sendgo API HTTP 클라이언트.
  class HttpClient
    def initialize(token_manager:, base_url:, api_version:)
      @token_manager = token_manager
      @base_url      = base_url
      @api_version   = api_version
    end

    def post(path, body)
      request(:post, path, body: body, is_retry: false)
    end

    # GET 요청. 캠페인 조회 엔드포인트에서 사용한다.
    # params 의 nil 값은 제외되어 서버 기본값이 적용된다.
    def get(path, params = {})
      request(:get, path, params: params, is_retry: false)
    end

    def put(path, body)
      request(:put, path, body: body, is_retry: false)
    end

    def patch(path, body)
      request(:patch, path, body: body, is_retry: false)
    end

    # DELETE 요청. 짧은 URL 리다이렉트 중지에서 사용한다.
    def delete(path)
      request(:delete, path, is_retry: false)
    end

    # multipart/form-data POST — 서류·이미지 첨부가 있는 관리 API 전용.
    #
    # 발신번호 등록과 이미지 템플릿은 JSON 으로 보낼 수 없다. multipart 에는
    # 배열도 불리언도 없으므로, Array/Hash 값은 JSON 문자열로 눌러 보낸다 —
    # 서버가 그렇게 받아 읽는다.
    #
    # files 는 { 필드명 => [파일명, IO 또는 문자열, content_type] } 형태다.
    # 같은 필드에 여러 파일을 붙이려면 배열로 넘긴다.
    def post_multipart(path, fields = {}, files = {})
      multipart_request(path, fields, files, is_retry: false)
    end

    private

    def request(method, path, body: nil, params: nil, is_retry: false)
      token = @token_manager.get_token
      url   = "#{@base_url}/api/#{@api_version}/#{path}"
      uri   = URI(url)

      if params && !params.empty?
        query = params.reject { |_, v| v.nil? }
        uri.query = URI.encode_www_form(query) unless query.empty?
      end

      req =
        case method
        when :get
          Net::HTTP::Get.new(uri)
        when :delete
          # 바디 없는 DELETE. Post 분기로 흘러가면 조용히 POST 로 나간다.
          Net::HTTP::Delete.new(uri)
        else
          # PUT/PATCH 도 여기서 잡는다. 클래스를 고르지 않고 else 로 흘리면
          # 전부 POST 로 나가서, 서버는 라우트를 못 찾고 405 를 준다.
          klass =
            case method
            when :put   then Net::HTTP::Put
            when :patch then Net::HTTP::Patch
            else Net::HTTP::Post
            end

          klass.new(uri).tap do |r|
            r["Content-Type"] = "application/json"
            r.body = body.to_json
          end
        end
      req["Authorization"] = bearer_auth(token)

      resp = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                             read_timeout: 15, open_timeout: 10) { |h| h.request(req) }

      resp_body = JSON.parse(resp.body) rescue {}

      unless resp.is_a?(Net::HTTPSuccess)
        error_code = resp_body["code"]
        endpoint   = path.split("/").last
        if !is_retry && @token_manager.should_refresh?(resp.code.to_i, error_code)
          @token_manager.invalidate
          return request(method, path, body: body, params: params, is_retry: true)
        end
        raise SendgoError.from_response(resp.code.to_i, resp_body, endpoint, @api_version)
      end

      resp_body
    end

    # 파일 내용을 미리 읽어 둔다. IO 는 한 번 소진되면 되감을 수 없어,
    # 그러지 않으면 토큰 갱신 후 재시도가 빈 파일을 올린다.
    def multipart_request(path, fields, files, is_retry:)
      parts = []

      fields.each do |name, value|
        next if value.nil?

        encoded =
          case value
          when true  then "1"
          when false then "0"
          when Array, Hash then JSON.generate(value)
          else value.to_s
          end

        parts << [:field, name.to_s, encoded]
      end

      files.each do |name, file|
        next if file.nil?

        # 파일 하나는 IO 이거나 [filename, io, content_type] 튜플이고,
        # 여러 개는 그 튜플들의 배열이다. 이 둘을 구분하지 않으면 튜플
        # 하나를 원소 세 개로 잘못 훑는다.
        entries = multiple_files?(file) ? file : [file]

        entries.each_with_index do |entry, index|
          # 여러 개면 서버가 attachments[0] 형태를 기대한다.
          field_name = entries.length > 1 || multiple_files?(file) ? "#{name}[#{index}]" : name.to_s
          filename, io, content_type = normalize_file(entry)
          parts << [:file, field_name, filename, read_all(io), content_type]
        end
      end

      send_multipart(path, parts, is_retry: is_retry)
    end

    # 파일 목록인지 단일 파일 튜플인지 판별한다.
    def multiple_files?(file)
      file.is_a?(Array) && (file.first.is_a?(Array) || file.first.respond_to?(:read))
    end

    def normalize_file(entry)
      case entry
      when Array
        filename, io, content_type = entry
        [filename, io, content_type || "application/octet-stream"]
      else
        filename = entry.respond_to?(:path) ? File.basename(entry.path) : "upload"
        [filename, entry, "application/octet-stream"]
      end
    end

    def read_all(io)
      io.respond_to?(:read) ? io.read : io.to_s
    end

    def send_multipart(path, parts, is_retry:)
      token    = @token_manager.get_token
      boundary = "----SendgoBoundary#{SecureRandom.hex(12)}"
      body     = build_multipart_body(parts, boundary)
      uri      = URI("#{@base_url}/api/#{@api_version}/#{path}")

      req = Net::HTTP::Post.new(uri)
      req["Content-Type"]  = "multipart/form-data; boundary=#{boundary}"
      req["Accept"]        = "application/json"
      req["Authorization"] = bearer_auth(token)
      req.body = body

      # 파일 업로드는 JSON 요청보다 오래 걸린다.
      resp = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                             read_timeout: 60, open_timeout: 10) { |h| h.request(req) }

      resp_body = JSON.parse(resp.body) rescue {}

      unless resp.is_a?(Net::HTTPSuccess)
        error_code = resp_body["code"]
        endpoint   = path.split("/").last
        if !is_retry && @token_manager.should_refresh?(resp.code.to_i, error_code)
          @token_manager.invalidate
          return send_multipart(path, parts, is_retry: true)
        end
        raise SendgoError.from_response(resp.code.to_i, resp_body, endpoint, @api_version)
      end

      resp_body
    end

    # 버퍼를 처음부터 BINARY 로 만들고 붙이는 조각마다 `.b` 를 건다.
    #
    # UTF-8 버퍼에 파일 바이트(ASCII-8BIT)를 붙이면, 앞서 넣은 필드 값에
    # 한글이 하나라도 있는 순간 Encoding::CompatibilityError 로 죽는다.
    # 발신번호 등록은 별칭이 한글이고 서류는 PDF 라 항상 그 조합이다.
    def build_multipart_body(parts, boundary)
      body = +"".b

      parts.each do |part|
        body << "--#{boundary}\r\n".b

        if part[0] == :field
          _, name, value = part
          body << %(Content-Disposition: form-data; name="#{name}"\r\n\r\n).b
          body << "#{value}\r\n".b
        else
          _, name, filename, content, content_type = part
          body << %(Content-Disposition: form-data; name="#{name}"; filename="#{filename}"\r\n).b
          body << "Content-Type: #{content_type}\r\n\r\n".b
          body << content.to_s.b
          body << "\r\n".b
        end
      end

      body << "--#{boundary}--\r\n".b
      body
    end

    def bearer_auth(token)
      return "Bearer #{token}" if @api_version == "v2"
      "Bearer #{Base64.strict_encode64(token)}"
    end
  end
end
