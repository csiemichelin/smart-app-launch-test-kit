require_relative 'token_payload_validation'

module SMARTAppLaunch
  class TokenResponseBodyTest < Inferno::Test
    include TokenPayloadValidation

    title 'Token exchange response body contains required information encoded in JSON'
    description %(
      EHR 授權伺服器在處理完授權請求後，會回傳一個 JSON 結構，這個結構會包含以下欄位：

      1. `access_token`：授權代碼交換成功後得到的 access token
      2. `token_type`：必須是 Bearer，表示 access token 的類型
      3. `scope`：表示授權範圍，即應用程式能夠存取的資源範圍
      4. `expires_in`：表示 token 的有效期，這在 refresh token 時是必需的

      如果有包含 fhirContext 這個欄位，那則會檢查其是否符合特定的格式。
    )
    id :smart_token_response_body

    input :requested_scopes
    output :id_token,
           :refresh_token,
           :access_token,
           :expires_in,
           :patient_id,
           :encounter_id,
           :received_scopes,
           :intent
    uses_request :token

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      assert_valid_json(request.response_body)
      token_response_body = JSON.parse(request.response_body)

      output id_token: token_response_body['id_token'],
             refresh_token: token_response_body['refresh_token'],
             access_token: token_response_body['access_token'],
             expires_in: token_response_body['expires_in'],
             patient_id: token_response_body['patient'],
             encounter_id: token_response_body['encounter'],
             received_scopes: token_response_body['scope'],
             intent: token_response_body['intent']

      validate_required_fields_present(token_response_body, ['access_token', 'token_type', 'expires_in', 'scope'])
      validate_token_field_types(token_response_body)
      validate_token_type(token_response_body)
      check_for_missing_scopes(requested_scopes, token_response_body) unless config.options[:ignore_missing_scopes_check]

      assert access_token.present?, 'Token response did not contain an access token'
      assert token_response_body['token_type']&.casecmp('Bearer')&.zero?,
             '`token_type` field must have a value of `Bearer`'

      validate_fhir_context(token_response_body['fhirContext'])
    end
  end
end
