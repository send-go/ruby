require_relative '../lib/sendgo'
url = ENV.fetch('SENDGO_TEST_URL') + '/'
begin
  Sendgo::AccountClient.new(agent_token: '')
  raise '빈 토큰 허용'
rescue ArgumentError
end
c = Sendgo::AccountClient.new(agent_token: 'test-agent', base_url: url)
raise "응답 오류" unless c.me()["message"] == "Success"
raise "응답 오류" unless c.organizations()["message"] == "Success"
raise "응답 오류" unless c.select_organization(nil)["message"] == "Success"
raise "응답 오류" unless c.select_organization("team-id")["message"] == "Success"
raise "응답 오류" unless c.api_keys()["message"] == "Success"
raise "응답 오류" unless c.create_api_key({"name" => "한글 이름", "ipAddresses" => [{"ip" => "192.0.2.1", "description" => "서버"}]})["message"] == "Success"
raise "응답 오류" unless c.api_key("key/id ?")["message"] == "Success"
raise "응답 오류" unless c.update_api_key("key/id ?", "새 이름")["message"] == "Success"
raise "응답 오류" unless c.delete_api_key("key/id ?")["message"] == "Success"
raise "응답 오류" unless c.issue_token("key/id ?")["message"] == "Success"
raise "응답 오류" unless c.allowed_ips("key/id ?")["message"] == "Success"
raise "응답 오류" unless c.add_allowed_ip("key/id ?", {"ip" => "192.0.2.1", "description" => "서버"})["message"] == "Success"
raise "응답 오류" unless c.delete_allowed_ip("key/id ?", "ip/id ?")["message"] == "Success"
[['expired', 401, 'AGENT_TOKEN_EXPIRED'], ['forbidden', 403, 'AGENT_ABILITY_MISSING']].each do |token, status, code|
  begin
    Sendgo::AccountClient.new(agent_token: token, base_url: url).me
    raise '오류가 발생하지 않음'
  rescue Sendgo::SendgoError => e
    raise e unless e.status_code == status && e.error_code == code
  end
end
