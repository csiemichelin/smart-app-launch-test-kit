module SMARTAppLaunch
  class CORSTokenExchangeTest < Inferno::Test
    title 'SMART Token Endpoint Enables Cross-Origin Resource Sharing (CORS)'
    description %(
      SMART規範要求支援純瀏覽器應用的伺服器，必須啟用 [CORS（Cross-Origin Resource Sharing）](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#considerations-for-cross-origin-resource-sharing-cors-support)。
        
        - 具體來說，CORS 設定必須允許來自客戶端註冊來源的請求，並且允許訪問 token 端點。

      這個測試會檢查 token 端點的回應是否正確地加上了 CORS header。
    )
    id :smart_cors_token_exchange

    uses_request :cors_token_request

    input :client_auth_type

    run do
      omit_if client_auth_type != 'public', %(
        Client type is not public, Cross-Origin Resource Sharing (CORS) is not required to be supported for
        non-public client types
      )

      skip_if request.status != 200, 'Previous request was unsuccessful, cannot check for CORS support'

      inferno_origin = Inferno::Application['inferno_host']
      cors_header = request.response_header('Access-Control-Allow-Origin')&.value

      assert cors_header == inferno_origin || cors_header == '*',
             "Request must have `Access-Control-Allow-Origin` header containing `#{inferno_origin}`"
    end
  end
end
