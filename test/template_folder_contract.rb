require_relative '../lib/sendgo'
c = Sendgo::Client.new(access_key: 'test-access', secret_key: 'test-secret', api_version: 'v2', base_url: ENV.fetch('SENDGO_TEST_URL'))
f = '11111111-1111-4111-8111-111111111111'
key = '채널 /?'
c.template_folders.list
c.template_folders.list(template_type: 'brand', kakao_sender_key: key)
c.template_folders.create(name: '주문')
c.template_folders.create(name: '하위', parent_uuid: f)
['notice', 'brand'].each do |kind|
  c.template_folders.assign(template_type: kind, kakao_sender_key: key, template_codes: ['코드 1', 'code/2'], folder_uuid: f)
  c.template_folders.assign(template_type: kind, kakao_sender_key: key, template_codes: ['코드 1'], folder_uuid: nil)
end
c.notice_templates.list(folder_uuid: 'none')
c.brand_templates.list(folder_uuid: f)
c.notice_templates.create(kakao_sender_key: key, template_name: '테스트', template_content: '본문', template_message_type: 'BA', template_emphasize_type: 'NONE', category_code: '001001', message_purpose: 'order_delivery', legal_basis: 'transaction', benefit_origin: 'none', expiry_type: 'none', folder_uuid: f)
c.brand_templates.create(kakao_sender_key: key, template_name: '테스트', template_type: 'FT', folder_uuid: f)
[['forbidden',403,'ACCESS_KEY_NOT_APPROVED'],['invalid',422,'VALIDATION_FAILED'],['missing',404,'TEMPLATE_FOLDER_NOT_FOUND']].each do |kind,status,code|
  begin
    c.template_folders.list(template_type: kind)
    raise '오류가 발생하지 않음'
  rescue Sendgo::SendgoError => e
    raise unless e.status_code == status && e.error_code == code
  end
end
