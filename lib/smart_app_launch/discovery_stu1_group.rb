require_relative 'well_known_capabilities_stu1_test'
require_relative 'well_known_endpoint_test'
require_relative 'url_helpers'

module SMARTAppLaunch
  class DiscoverySTU1Group < Inferno::TestGroup
    id :smart_discovery
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

      這個測試套件會檢查 `/metadata` 和 `/.well-known/smart-configuration` 端點中
      提供的 SMART on FHIR 設定，確認是否符合規範。

      想了解更多細節，可以參考以下文件：

      * [SMART App Launch Framework](https://www.hl7.org/fhir/smart-app-launch/1.0.0/conformance/index.html)
      * [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
      * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
    )

    test from: :well_known_endpoint,
         id: 'Test01'
    test from: :well_known_capabilities_stu1,
         id: 'Test02'

    test do
      include URLHelpers

      title 'Conformance/CapabilityStatement provides OAuth 2.0 endpoints'
      description %(
        如果 FHIR server 要使用 SMART on FHIR 授權機制來控制存取權限，那它的 metadata 裡面必須提供 OAuth2 相關的網址，讓其他系統能夠自動找到授權和驗證的端點。
      )
      input :url
      output :capability_authorization_url,
             :capability_introspection_url,
             :capability_management_url,
             :capability_registration_url,
             :capability_revocation_url,
             :capability_token_url

      fhir_client do
        url :url
      end

      run do
        fhir_get_capability_statement

        assert_response_status(200)

        smart_extension =
          resource
            .rest
            &.map(&:security)
            &.compact
            &.find do |security|
              security.service&.any? do |service|
                service.coding&.any? do |coding|
                  coding.code == 'SMART-on-FHIR'
                end
              end
            end
            &.extension
            &.find do |extension|
              extension.url == 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'
            end

        assert smart_extension.present?, 'No SMART extensions found in CapabilityStatement'

        oauth_extension_urls = ['authorize', 'introspect', 'manage', 'register', 'revoke', 'token']

      base_url = "#{url.chomp('/')}/"
        oauth_urls = oauth_extension_urls.each_with_object({}) do |url, urls|
          urls[url] = smart_extension.extension.find { |extension| extension.url == url }&.valueUri
          urls[url] = make_url_absolute(base_url, urls[url])
        end

        output capability_authorization_url: oauth_urls['authorize'],
               capability_introspection_url: oauth_urls['introspect'],
               capability_management_url: oauth_urls['manage'],
               capability_registration_url: oauth_urls['register'],
               capability_revocation_url: oauth_urls['revoke'],
               capability_token_url: oauth_urls['token']

        assert oauth_urls['authorize'].present?, 'No `authorize` extension found'
        assert oauth_urls['token'].present?, 'No `token` extension found'
      end
    end

    test do
      title 'OAuth 2.0 Endpoints in the conformance statement match those from the well-known configuration'
      description %(
        FHIR 伺服器必須透過 `CapabilityStatement` 和 `/.well-known/smart-configuration` 這兩種方式，提供 OAuth 授權端點資訊，讓應用程式開發者能夠發現並使用這些端點進行身份驗證與授權。
      )

      input :well_known_authorization_url,
            optional: true
      input :well_known_introspection_url,
            optional: true
      input :well_known_management_url,
            optional: true
      input :well_known_registration_url,
            optional: true
      input :well_known_revocation_url,
            optional: true
      input :well_known_token_url,
            optional: true
      input :capability_authorization_url,
            optional: true
      input :capability_introspection_url,
            optional: true
      input :capability_management_url,
            optional: true
      input :capability_registration_url,
            optional: true
      input :capability_revocation_url,
            optional: true
      input :capability_token_url,
            optional: true
      output :smart_authorization_url,
             :smart_introspection_url,
             :smart_management_url,
             :smart_registration_url,
             :smart_revocation_url,
             :smart_token_url

      run do
        mismatched_urls = []
        ['authorization', 'token', 'introspection', 'management', 'registration', 'revocation'].each do |type|
          well_known_url = send("well_known_#{type}_url")
          capability_url = send("capability_#{type}_url")

          output "smart_#{type}_url": well_known_url.presence || capability_url.presence

          mismatched_urls << type if well_known_url != capability_url
        end

        pass_if mismatched_urls.empty?

        error_message = 'The following urls do not match:'

        mismatched_urls.each do |type|
          well_known_url = send("well_known_#{type}_url")
          capability_url = send("capability_#{type}_url")

          error_message += "\n- #{type.capitalize}:"
          error_message += "\n  - Well-Known: #{well_known_url}\n  - CapabilityStatement: #{capability_url}"
        end

        assert false, error_message
      end
    end
  end
end
