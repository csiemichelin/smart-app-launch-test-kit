require_relative 'app_launch_test'
require_relative 'app_redirect_test'
require_relative 'code_received_test'
require_relative 'launch_received_test'
require_relative 'token_exchange_test'
require_relative 'token_response_body_test'
require_relative 'token_response_headers_test'

module SMARTAppLaunch
  class EHRLaunchGroup < Inferno::TestGroup
    id :smart_ehr_launch
    title 'SMART EHR Launch With Practitioner Scope'
    short_description 'Demonstrate the ability to authorize an app using the EHR Launch.'

    input :ehr_tls_mode,
          title: 'EHR Launch Practitioner App HTTPS TLS verification',
          type: 'radio',
          default: 'true',
          options: {
            list_options: [
              {
                label: 'Enabled',
                value: 'true'
              },
              {
                label: 'Disabled',
                value: 'false'
              }
            ]
          }

    description %(
      # 背景說明

      The [EHR
      Launch](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html#ehr-launch-sequence)
      這是 SMART App Launch 框架中兩種啟動方式之一（另一種是 Standalone 啟動）。
      應用程式是從一個現有的 EHR session 或入口網站啟動的，透過重定向到註冊的啟動 URL。
      EHR 會提供應用程式兩個參數：

      * `iss` - 包含 FHIR 伺服器的 URL
      * `launch` - 授權所需的識別碼

      # 測試方法

      Inferno 執行時會等待來自 EHR 伺服器的重定向，並在收到重定向後檢查 iss 和 launch 參數是否存在。
      接著，會檢查授權端點（authorization endpoint）的安全性，並使用提供的 launch 識別碼嘗試授權。

      更多有關 #{title} 的資訊：

      * [SMART EHR Launch Sequence](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html#ehr-launch-sequence)
    )

    config(
      inputs: {
        client_id: {
          name: :ehr_client_id,
          title: 'EHR Launch Client ID',
          description: 'Client ID provided during registration of Inferno as an EHR launch application'
        },
        client_secret: {
          name: :ehr_client_secret,
          title: 'EHR Launch Client Secret',
          description: 'Client Secret provided during registration of Inferno as an EHR launch application. ' \
                       'Only for clients using confidential symmetric authentication.'
        },
        requested_scopes: {
          name: :ehr_requested_scopes,
          title: 'EHR Launch Scope',
          description: 'OAuth 2.0 scope provided by system to enable all required functionality',
          type: 'textarea',
          default: 'launch openid fhirUser offline_access user/*.read'
        },
        url: {
          title: 'EHR Launch FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by EHR launched applications'
        },
        code: {
          name: :ehr_code
        },
        state: {
          name: :ehr_state
        },
        launch: {
          name: :ehr_launch
        },
        smart_credentials: {
          name: :ehr_smart_credentials
        },
        ehr_tls_mode: {
          title: 'EHR Launch Practitioner App HTTPS TLS verification',
          type: 'radio',
          default: 'true',
          options: {
            list_options: [
              {
                label: 'Enabled',
                value: 'true'
              },
              {
                label: 'Disabled',
                value: 'false'
              }
            ]
          }
        }
      },
      outputs: {
        launch: { name: :ehr_launch },
        code: { name: :ehr_code },
        token_retrieval_time: { name: :ehr_token_retrieval_time },
        state: { name: :ehr_state },
        id_token: { name: :ehr_id_token },
        refresh_token: { name: :ehr_refresh_token },
        access_token: { name: :ehr_access_token },
        expires_in: { name: :ehr_expires_in },
        patient_id: { name: :ehr_patient_id },
        encounter_id: { name: :ehr_encounter_id },
        received_scopes: { name: :ehr_received_scopes },
        intent: { name: :ehr_intent },
        smart_credentials: { name: :ehr_smart_credentials },
        ehr_tls_mode: { name: :ehr_tls_mode }
      },
      requests: {
        launch: { name: :ehr_launch },
        redirect: { name: :ehr_redirect },
        token: { name: :ehr_token }
      }
    )

    input_order :url,
                :ehr_client_id,
                :ehr_client_secret,
                :ehr_requested_scopes
                :ehr_tls_mode

    test from: :smart_app_launch
    test from: :smart_launch_received
    if config.options[:ehr_tls_mode]&.call == true
      test from: :tls_version_test,
          id: :ehr_auth_tls,
          title: 'OAuth 2.0 authorize endpoint secured by transport layer security',
          description: %(
            應用程式必須確保敏感資訊（authentication secrets、
            authorization codes、tokens）只能透過 TLS 加密通道傳輸至已驗證的伺服器，以確保安全性。
          ),
          config: {
            inputs: { url: { name: :smart_authorization_url } },
            options: {  minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
          }
    end
    test from: :smart_app_redirect do
      input :launch
    end
    test from: :smart_code_received
    if config.options[:ehr_tls_mode]&.call == true
      test from: :tls_version_test,
          id: :ehr_token_tls,
          title: 'OAuth 2.0 token endpoint secured by transport layer security',
          description: %(
            應用程式必須確保敏感資訊（authentication secrets、
            authorization codes、tokens）只能透過 TLS 加密通道傳輸至已驗證的伺服器，以確保安全性。
          ),
          config: {
            inputs: { url: { name: :smart_token_url } },
            options: {  minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
          }
    end
    test from: :smart_token_exchange
    test from: :smart_token_response_body
    test from: :smart_token_response_headers
  end
end
