require_relative 'token_refresh_test'
require_relative 'token_refresh_body_test'
require_relative 'token_response_headers_test'

module SMARTAppLaunch
  class TokenRefreshGroup < Inferno::TestGroup
    id :smart_token_refresh
    title 'SMART Token Refresh'
    short_description 'Demonstrate the ability to exchange a refresh token for an access token.'
    description %(
      # 背景說明

      #{title} 測試會檢查系統是否能成功地使用 refresh token 換取新的 access token。
      refresh token 通常比 access token 有效期限長，可以讓客戶端應用程式獲取新的 access token，
      但 refresh token 本身不能用來直接存取伺服器上的資源。

      refresh token 的交換是透過 POST 請求發送到 token 交換端點，這在 [SMART App Launch
      Framework](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token) 中有詳細說明。

      # 測試方法

      這個測試會嘗試使用 refresh token 換取新的 access token，並確認回應中的資訊是否包含所需的欄位，
      以及是否使用了正確的標頭。

      更多資訊請參見：

      * [The OAuth 2.0 Authorization
        Framework](https://tools.ietf.org/html/rfc6749)
      * [Using a refresh token to obtain a new access
        token](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)
    )

    test from: :smart_token_refresh
    test from: :smart_token_refresh_body
    test from: :smart_token_response_headers,
         config: {
           requests: {
             token: { name: :token_refresh }
           }
         }
  end
end
