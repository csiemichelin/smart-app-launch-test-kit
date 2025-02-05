require_relative 'url_helpers'

module SMARTAppLaunch
  class CORSWellKnownEndpointTest < Inferno::Test
    include URLHelpers

    title 'SMART .well-known/smart-configuration Endpoint Enables Cross-Origin Resource Sharing (CORS)'
    id :smart_cors_well_known_endpoint
    description %(
      SMART規範要求支援純瀏覽器應用的伺服器，必須啟用 [CORS（Cross-Origin Resource Sharing）](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#considerations-for-cross-origin-resource-sharing-cors-support)。
        
        - 具體來說，CORS 設定必須允許來自任何來源的請求，尤其是對於公開的端點（例如 .well-known/smart-configuration 和 metadata）。
        
      這個測試會檢查 .well-known/smart-configuration 回應時，是否正確地加上了 CORS header，這樣瀏覽器才能順利地去存取這些端點。
    )
    optional

    input :url,
          title: 'FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by SMART applications'

    run do
      well_known_configuration_url = "#{url.chomp('/')}/.well-known/smart-configuration"
      inferno_origin = Inferno::Application['inferno_host']

      get(well_known_configuration_url,
          headers: { 'Accept' => 'application/json',
                     'Origin' => inferno_origin })
      assert_response_status(200)

      cors_allow_origin = request.response_header('Access-Control-Allow-Origin')&.value
      assert cors_allow_origin.present?, 'No `Access-Control-Allow-Origin` header received.'
      assert cors_allow_origin == inferno_origin || cors_allow_origin == '*',
             "`Access-Control-Allow-Origin` must be `#{inferno_origin}`, but received: `#{cors_allow_origin}`"
    end
  end
end
