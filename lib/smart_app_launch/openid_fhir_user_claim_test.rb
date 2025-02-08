module SMARTAppLaunch
  class OpenIDFHIRUserClaimTest < Inferno::Test
    id :smart_openid_fhir_user_claim
    title 'FHIR resource representing the current user can be retrieved'
    description %(
      確認 ID token 中是否包含 `fhirUser` 欄位，並且能成功取得它所指向的 FHIR 資源。
      `fhirUser` 必須是一個 URL，對應到 Patient、Practitioner、RelatedPerson 或 Person 這四種 FHIR 資源之一。
    )

    input :id_token_payload_json, :requested_scopes, :url
    input :smart_credentials, type: :oauth_credentials
    output :id_token_fhir_user

    fhir_client do
      url :url
      oauth_credentials :smart_credentials
    end

    run do
      skip_if id_token_payload_json.blank?
      # skip_if !requested_scopes&.include?('fhirUser'), '`fhirUser` scope not requested'

      assert_valid_json(id_token_payload_json)
      payload = JSON.parse(id_token_payload_json)
      fhir_user = payload['fhirUser']

      valid_fhir_user_resource_types = ['Patient', 'Practitioner', 'RelatedPerson', 'Person']

      if !fhir_user.present?
        # fhir_user 有值，進行正常檢查
        fhir_user_segments = fhir_user.split('/')
        fhir_user_resource_type = fhir_user_segments[-2]
        fhir_user_id = fhir_user_segments.last

        assert valid_fhir_user_resource_types.include?(fhir_user_resource_type),
              "ID token `fhirUser` claim does not refer to a valid resource type: #{fhir_user}"

        output id_token_fhir_user: fhir_user

        fhir_read(fhir_user_resource_type, fhir_user_id)

        assert_response_status(200)
        assert_resource_type(fhir_user_resource_type)
      else
        # fhir_user 沒有值
        skip_if !requested_scopes&.include?('fhirUser') || !requested_scopes&.include?('openid'),
                '`fhirUser` or `openid` scope not requested'
        
        assert_response_status(200) # 符合條件回傳 200
      end
    end
  end
end
