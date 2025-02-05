require_relative 'token_payload_validation'

module SMARTAppLaunch
  class TokenResponseBodyTestSTU22 < TokenResponseBodyTest
    title 'Token exchange response body contains required information encoded in JSON'
    description %(
      EHR 授權伺服器在處理完授權請求後，會回傳一個 JSON 結構，這個結構會包含以下欄位：

      1. `access_token`：授權代碼交換成功後得到的 access token
      2. `token_type`：必須是 Bearer，表示 access token 的類型
      3. `scope`：表示授權範圍，即應用程式能夠存取的資源範圍
      4. `expires_in`：表示 token 的有效期，這在 refresh token 時是必需的

      如果有包含 fhirContext 這個欄位，那則會檢查其是否符合特定的格式。
    )
    id :smart_token_response_body_stu2_2

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

    def validate_fhir_context(fhir_context)
      validate_fhir_context_stu2_2(fhir_context)
    end
  end
end
