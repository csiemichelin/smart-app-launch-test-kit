module SMARTAppLaunch
  class CORSOpenIDFHIRUserClaimTest < Inferno::Test
    id :smart_cors_openid_fhir_user_claim
    title 'SMART FHIR User REST API Endpoint Enables Cross-Origin Resource Sharing (CORS)'
    description %(
      SMART規範要求支援純瀏覽器應用的伺服器，必須啟用 [CORS（Cross-Origin Resource Sharing）](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#considerations-for-cross-origin-resource-sharing-cors-support)。
        
        - 具體來說，CORS 設定必須允許來自客戶端註冊來源的請求，並且允許訪問 token 端點及 FHIR REST API 端點。

      這個測試會檢查對 FHIR REST API 端點的請求是否包含正確的 CORS header 回應。
    )
    optional

    input :url, :id_token_fhir_user
    input :smart_credentials, type: :oauth_credentials

    fhir_client do
      url :url
      oauth_credentials :smart_credentials
      headers 'Origin' => Inferno::Application['inferno_host']
    end

    run do
      valid_fhir_user_resource_types = ['Patient', 'Practitioner', 'RelatedPerson', 'Person']

      fhir_user_segments = id_token_fhir_user.split('/')
      fhir_user_resource_type = fhir_user_segments[-2]
      fhir_user_id = fhir_user_segments.last

      assert valid_fhir_user_resource_types.include?(fhir_user_resource_type),
             "ID token `fhirUser` claim does not refer to a valid resource type: #{id_token_fhir_user}"

      fhir_read(fhir_user_resource_type, fhir_user_id)

      assert_response_status(200)

      inferno_origin = Inferno::Application['inferno_host']
      cors_allow_origin = request.response_header('Access-Control-Allow-Origin')&.value
      assert cors_allow_origin.present?, 'No `Access-Control-Allow-Origin` header received.'
      assert cors_allow_origin == inferno_origin || cors_allow_origin == '*',
             "`Access-Control-Allow-Origin` must be `#{inferno_origin}`, but received: `#{cors_allow_origin}`"
    end
  end
end
