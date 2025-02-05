require_relative 'url_helpers'

module SMARTAppLaunch
  class CORSMetadataRequest < Inferno::Test
    id :smart_cors_metadata_request

    include URLHelpers

    title 'SMART metadata Endpoint Enables Cross-Origin Resource Sharing (CORS)'
    description %(
      SMART規範要求支援純瀏覽器應用的伺服器，必須啟用 [CORS（Cross-Origin Resource Sharing）](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#considerations-for-cross-origin-resource-sharing-cors-support)。
        
        - 具體來說，CORS 設定必須允許來自任何來源的請求，尤其是對於公開的端點（例如 .well-known/smart-configuration 和 metadata）。

      這個測試會檢查 metadata 請求的回應時，是否正確地加上了 CORS header，這樣瀏覽器才能順利地存取這些端點。
    )
    optional

    input :url

    fhir_client do
      url :url
      headers 'Origin' => Inferno::Application['inferno_host']
    end

    run do
      fhir_get_capability_statement

      assert_response_status(200)
      inferno_origin = Inferno::Application['inferno_host']
      cors_allow_origin = request.response_header('Access-Control-Allow-Origin')&.value
      assert cors_allow_origin.present?, 'No `Access-Control-Allow-Origin` header received.'
      assert cors_allow_origin == inferno_origin || cors_allow_origin == '*',
             "`Access-Control-Allow-Origin` must be `#{inferno_origin}`, but received: `#{cors_allow_origin}`"
    end
  end
end
