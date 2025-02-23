require 'tls_test_kit'

require_relative 'jwks'
require_relative 'version'
require_relative 'discovery_stu1_group'
require_relative 'standalone_launch_group'
require_relative 'ehr_launch_group'
require_relative 'openid_connect_group'
require_relative 'token_refresh_group'

module SMARTAppLaunch
  class SMARTSTU1Suite < Inferno::TestSuite
    id 'smart'
    title 'SMART App Launch STU1'
    version VERSION

    resume_test_route :get, '/launch' do |request|
      request.query_parameters['iss']
    end

    resume_test_route :get, '/redirect' do |request|
      request.query_parameters['state']
    end

    route(
      :get,
      '/.well-known/jwks.json',
      ->(_env) { [200, { 'Content-Type' => 'application/json' }, [JWKS.jwks_json]] }
    )

    config options: {
      redirect_uri: "#{Inferno::Application['base_url']}/custom/smart/redirect",
      launch_uri: "#{Inferno::Application['base_url']}/custom/smart/launch"
    }

    description <<~DESCRIPTION
      SMART App Launch 測試套件用來檢查系統是否正確實作 [SMART App Launch IG](http://hl7.org/fhir/smart-app-launch/1.0.0/)，
      以提供授權或驗證服務給存取 HL7® FHIR® API 的客戶端應用程式。要開始測試，
      請先把 Inferno 客戶端註冊為一個 SMART 應用程式，以下是需要的資訊：

      * SMART Launch URI: `#{config.options[:launch_uri]}`
      * OAuth Redirect URI: `#{config.options[:redirect_uri]}`
    DESCRIPTION

    input_instructions %(
        使用以下資訊將 Inferno 註冊為一個 SMART 應用程式：

        * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
        * Oauth Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`
      )

    group do
      title 'Standalone Launch Patient App'
      short_title 'Standalone Launch Patient App'
      id :smart_full_standalone_launch

      input_instructions %(
        將 Inferno 註冊為一個 standalone 的應用程式，使用以下資訊：

        * Oauth Redirect URI: `#{config.options[:redirect_uri]}`

        記得輸入適當的 scope，讓應用程式能以 patient-level 存取所有相關資源。
        此外，還需要支援 OpenID Connect（openid fhirUser）、refresh tokens（offline_access）
        以及 patient context（launch/patient）。
      )

      description %(
        這個情境測試主要驗證系統是否能執行一次完整的 SMART App 啟動流程。具體來說，是進行
        一個以病患為中心的獨立啟動（Patient Standalone Launch），模擬一個符合 
        SMART on FHIR 標準的機密客戶端，並包括以下功能：patient context、refresh token、
        OpenID Connect (OIDC) identity token，以及使用 GET HTTP 方法進行授權碼交換。

        測試流程如下：

        1. 啟動後，對當前病患執行一次簡單的 Patient 資源讀取操作
        2. 接著使用 refresh token 更新 access token，並用新的 token 再次讀取 Patient 資源，以確認刷新是否成功
        3. 解碼並驗證 OpenID Connect 提供的身分驗證資訊
        
        在測試前，需要將 Inferno 註冊為一個機密客戶端，並使用以下資訊：

        * Oauth Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

        此情境相關的實作規範包括：

        * [SMART on FHIR
          (STU1)](http://www.hl7.org/fhir/smart-app-launch/1.0.0/)
        * [SMART on FHIR
          (STU2)](http://hl7.org/fhir/smart-app-launch/STU2)
        * [OpenID Connect
          (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html)
      )

      run_as_group

      group from: :smart_discovery
      group from: :smart_standalone_launch

      group from: :smart_openid_connect,
            config: {
              inputs: {
                id_token: { name: :standalone_id_token },
                client_id: { name: :standalone_client_id },
                requested_scopes: { name: :standalone_requested_scopes },
                access_token: { name: :standalone_access_token },
                smart_credentials: { name: :standalone_smart_credentials }
              }
            }

      group from: :smart_token_refresh,
            id: :smart_standalone_refresh_without_scopes,
            title: 'SMART Token Refresh Without Scopes',
            config: {
              inputs: {
                refresh_token: { name: :standalone_refresh_token },
                client_id: { name: :standalone_client_id },
                client_secret: { name: :standalone_client_secret },
                received_scopes: { name: :standalone_received_scopes }
              },
              outputs: {
                refresh_token: { name: :standalone_refresh_token },
                received_scopes: { name: :standalone_received_scopes },
                access_token: { name: :standalone_access_token },
                token_retrieval_time: { name: :standalone_token_retrieval_time },
                expires_in: { name: :standalone_expires_in },
                smart_credentials: { name: :standalone_smart_credentials }
              }
            }

      group from: :smart_token_refresh,
            id: :smart_standalone_refresh_with_scopes,
            title: 'SMART Token Refresh With Scopes',
            config: {
              options: { include_scopes: true },
              inputs: {
                refresh_token: { name: :standalone_refresh_token },
                client_id: { name: :standalone_client_id },
                client_secret: { name: :standalone_client_secret },
                received_scopes: { name: :standalone_received_scopes }
              },
              outputs: {
                refresh_token: { name: :standalone_refresh_token },
                received_scopes: { name: :standalone_received_scopes },
                access_token: { name: :standalone_access_token },
                token_retrieval_time: { name: :standalone_token_retrieval_time },
                expires_in: { name: :standalone_expires_in },
                smart_credentials: { name: :standalone_smart_credentials }
              }
            }
    end

    group do
      title 'EHR Launch Practitioner App'
      short_title 'EHR Launch Practitioner App'
      id :smart_full_ehr_launch

      input_instructions <<~INSTRUCTIONS
        將 Inferno 註冊為一個由 EHR 啟動的應用程式，使用以下資訊：

        * SMART Launch URI: `#{config.options[:launch_uri]}`
        * OAuth Redirect URI: `#{config.options[:redirect_uri]}`

        記得輸入適當的 scope，讓應用程式能以 user-level 存取所有相關資源，
        如果使用的是 SMART v2，則必須使用 v2 格式的 scope。
        此外，還需要支援 OpenID Connect（openid fhirUser）、refresh tokens（offline_access）以及 EHR context（launch）。
        EHR context 代表 EHR 系統的整體背景，而這個測試中 EHR 預期會以 patient context 來啟動應用程式。

        在按下提交後，Inferno 會等待測試中的 EHR 系統啟動應用程式。
      INSTRUCTIONS

      description %(
        這個情境測試主要驗證系統是否能夠執行一次完整的 EHR 啟動流程。具體來說，
        這個測試執行的是一次 EHR 啟動，並模擬一個 EHR 系統啟動一個符合 SMART 標準的應用程式，
        且包括以下功能：patient context、refresh token、OpenID Connect (OIDC) identity token，
        需要注意的是，只有在 SMART v2 中，才會使用 POST HTTP 方法進行授權碼交換。

        測試流程如下：

        1. 啟動後，對當前病患執行一次簡單的 Patient 資源讀取操作
        2. 接著使用 refresh token 更新 access token，並用新的 token 再次讀取 Patient 資源，以確認刷新是否成功
        3. 解碼並驗證 OpenID Connect 提供的身分驗證資訊

        在測試前，需要將 Inferno 註冊為一個 EHR 啟動的機密客戶端，並使用以下資訊：

        * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
        * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

        如果你的 EHR 系統使用 Internet Explorer 11 顯示嵌入的應用程式，請參考 [instructions on how to complete the EHR Practitioner App
        test](https://github.com/onc-healthit/onc-certification-g10-test-kit/wiki/Completing-EHR-Practitioner-App-test-in-Internet-Explorer/).

        此情境相關的實作規範包括：

        * [SMART on FHIR
          (STU1)](http://www.hl7.org/fhir/smart-app-launch/1.0.0/)
        * [SMART on FHIR
          (STU2)](http://hl7.org/fhir/smart-app-launch/STU2)
        * [OpenID Connect
          (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html)
      )

      run_as_group

      group from: :smart_discovery

      group from: :smart_ehr_launch

      group from: :smart_openid_connect,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                smart_credentials: { name: :ehr_smart_credentials }
              }
            }

      group from: :smart_token_refresh,
            id: :smart_ehr_refresh_without_scopes,
            title: 'SMART Token Refresh Without Scopes',
            config: {
              inputs: {
                refresh_token: { name: :ehr_refresh_token },
                client_id: { name: :ehr_client_id },
                client_secret: { name: :ehr_client_secret },
                received_scopes: { name: :ehr_received_scopes }
              },
              outputs: {
                refresh_token: { name: :ehr_refresh_token },
                received_scopes: { name: :ehr_received_scopes },
                access_token: { name: :ehr_access_token },
                token_retrieval_time: { name: :ehr_token_retrieval_time },
                expires_in: { name: :ehr_expires_in },
                smart_credentials: { name: :ehr_smart_credentials }
              }
            }

      group from: :smart_token_refresh,
            id: :smart_ehr_refresh_with_scopes,
            title: 'SMART Token Refresh With Scopes',
            config: {
              options: { include_scopes: true },
              inputs: {
                refresh_token: { name: :ehr_refresh_token },
                client_id: { name: :ehr_client_id },
                client_secret: { name: :ehr_client_secret },
                received_scopes: { name: :ehr_received_scopes }
              },
              outputs: {
                refresh_token: { name: :ehr_refresh_token },
                received_scopes: { name: :ehr_received_scopes },
                access_token: { name: :ehr_access_token },
                token_retrieval_time: { name: :ehr_token_retrieval_time },
                expires_in: { name: :ehr_expires_in },
                smart_credentials: { name: :ehr_smart_credentials }
              }
            }
    end
  end
end
