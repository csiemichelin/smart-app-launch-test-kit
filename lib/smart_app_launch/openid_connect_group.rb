require 'jwt'
require_relative 'openid_decode_id_token_test'
require_relative 'openid_retrieve_configuration_test'
require_relative 'openid_required_configuration_fields_test'
require_relative 'openid_retrieve_jwks_test'
require_relative 'openid_token_header_test'
require_relative 'openid_token_payload_test'
require_relative 'openid_fhir_user_claim_test'

module SMARTAppLaunch
  class OpenIDConnectGroup < Inferno::TestGroup
    id :smart_openid_connect
    title 'OpenID Connect'
    short_description 'Demonstrate the ability to authenticate users with OpenID Connect.'

    description %(
      # 背景說明

      OpenID Connect (OIDC) 提供驗證授權使用者身份的功能。
      在 [SMART App Launch Framework](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html) 中，
      應用程式可以透過在授權請求中加入 openid 和 fhirUser 範圍（scopes），來要求返回一個 id_token，
      用來驗證使用者的身份，例如患者、醫療人員等。

      # 測試方法

      這個測試會驗證 OAuth 2.0 Token 回應中所返回的 id_token。流程如下：

      1. 解碼 id_token
      2. 從 FHIR 伺服器的 well-known 配置端點取得 OIDC 設定，並檢查是否包含所有必須的欄位
      3. 從 OIDC 配置中提供的網址拿到用來簽章 id_token 的密鑰
      4. 驗證 id_token 的標頭、內容和簽章是否正確。
      5. 最後會從 FHIR 伺服器抓取 id_token 裡 fhirUser 欄位對應的 FHIR 資源

      更多資訊請參考：

      * [SMART App Launch Framework](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html)
      * [Scopes for requesting identity data](https://www.hl7.org/fhir/smart-app-launch/1.0.0/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
      * [Apps Requesting Authorization](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html#step-1-app-asks-for-authorization)
      * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
    )

    test from: :smart_openid_decode_id_token

    test from: :smart_openid_retrieve_configuration

    test from: :smart_openid_required_configuration_fields

    test from: :smart_openid_retrieve_jwks

    test from: :smart_openid_token_header

    test from: :smart_openid_token_payload

    test from: :smart_openid_fhir_user_claim
  end
end
