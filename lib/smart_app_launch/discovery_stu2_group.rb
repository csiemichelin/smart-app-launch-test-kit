require_relative 'well_known_capabilities_stu2_test'
require_relative 'well_known_endpoint_test'

module SMARTAppLaunch
  class DiscoverySTU2Group < Inferno::TestGroup
    id :smart_discovery_stu2
    title 'SMART on FHIR Discovery'
    short_description 'Retrieve server\'s SMART on FHIR configuration.'
    description %(
      # 背景說明

      #{title} 測試流程旨在檢查授權端點與 SMART 功能是否符合  [SMART App Launch
      Framework](https://www.hl7.org/fhir/smart-app-launch/1.0.0/conformance/index.html) 的規範，
      該框架利用 OAuth 2.0 為像 Inferno 這樣的應用程式進行授權，允許其存取 FHIR 伺服器上的特定資訊。
      透過授權端點，使用者可以授權這些應用程式存取資料，而無需直接提供帳號密碼，
      應用程式會獲得一個 access token 來訪問 FHIR 伺服器上的資源，
      這個 access token 具有一定的有效期限並附帶權限範圍（scopes）。
      此外，應用程式可能還會取得一個 refresh token 用於交換新的 access token，
      但這個 refresh token 不會與 FHIR 伺服器共享。
      如果使用 OpenID Connect，系統還可能提供一個 id token，這個 token 用於驗證使用者身份，
      並且經過數位簽章來協助確認使用者的真實身份。

      # 測試方法

      這個測試套件會檢查 /.well-known/smart-configuration 端點中提供的 SMART on FHIR 設定，確認是否符合規範。

      想了解更多細節，可以參考以下文件：

      * [SMART App Launch Framework](https://www.hl7.org/fhir/smart-app-launch/1.0.0/conformance/index.html)
      * [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
      * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
    )

    test from: :well_known_endpoint,
         config: {
           outputs: {
             well_known_authorization_url: { name: :smart_authorization_url },
             well_known_token_url: { name: :smart_token_url }
           }
         }
    test from: :well_known_capabilities_stu2
  end
end
