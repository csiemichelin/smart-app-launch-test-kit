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
      The SMART App Launch Test Suite verifies that systems correctly implement 
      the [SMART App Launch IG](http://hl7.org/fhir/smart-app-launch/1.0.0/) 
      for providing authorization and/or authentication services to client 
      applications accessing HL7® FHIR® APIs. To get started, please first register 
      the Inferno client as a SMART App with the following information:

      * SMART Launch URI: `#{config.options[:launch_uri]}`
      * OAuth Redirect URI: `#{config.options[:redirect_uri]}`
    DESCRIPTION

    group do
      title 'Standalone Launch Patient App'
      short_title 'Standalone Launch Patient App'
      id :smart_full_standalone_launch

      input_instructions %(
        Register Inferno as a standalone application using the following information:

        * Redirect URI: `#{config.options[:redirect_uri]}`

        Enter in the appropriate scope to enable patient-level access to all
        relevant resources. In addition, support for the OpenID Connect (openid
        fhirUser), refresh tokens (offline_access), and patient context
        (launch/patient) are required.
      )

      description %(
        這個情境測試主要驗證系統是否能執行一次完整的 SMART App 啟動流程。具體來說，是進行
        一個以患者為中心的獨立啟動（Patient Standalone Launch），模擬一個符合 
        SMART on FHIR 標準的機密客戶端，並包括以下功能：patient context、refresh token、
        OpenID Connect (OIDC) identity token，以及使用 GET HTTP 方法進行授權碼交換。

        測試流程如下：

        1. 啟動後，對當前患者執行一次簡單的 Patient 資源讀取操作
        2. 接著使用 refresh token 更新 access token，並用新的 token 再次讀取 Patient 資源，以確認刷新是否成功
        3 .將 OIDC 提供的身分驗證資訊解碼並驗證
        
        在測試前，需要將 Inferno 註冊為一個機密客戶端，並使用以下資訊：

        * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

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
      title 'EHR Launch'
      id :smart_full_ehr_launch

      input_instructions <<~INSTRUCTIONS
        Please register the Inferno client as a SMART App with the following
        information:

        * SMART Launch URI: `#{config.options[:launch_uri]}`
        * OAuth Redirect URI: `#{config.options[:redirect_uri]}`
      INSTRUCTIONS

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
