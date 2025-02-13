require_relative 'app_redirect_test'
require_relative 'code_received_test'
require_relative 'token_exchange_test'
require_relative 'token_response_body_test'
require_relative 'token_response_headers_test'

module SMARTAppLaunch
  class StandaloneLaunchGroup < Inferno::TestGroup
    id :smart_standalone_launch
    title 'Standalone Launch With Patient Scope'
    short_description 'Demonstrate the ability to authorize an app using the Standalone Launch.'

    input :standalone_tls_mode,
          title: 'Standalone Launch Patient App HTTPS TLS verification',
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

      The [Standalone
      Launch Sequence](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
      是一種允許應用程式（例如 Inferno）不依賴現有 EHR session 即可啟動的方法。
      這是 SMART App Launch 框架中兩種啟動方式之一（另一種是 EHR 啟動）。
      應用程式會向授權端點（authorization endpoint）發送指定範圍（scopes）的授權請求，
      並最終獲取 access token，用於存取 FHIR 伺服器上的資源。

      # 測試方法

      Inferno 會先將使用者導向授權端點（authorization endpoint），
      讓使用者提供必要的授權資訊，例如選擇要操作的病患。
      授權成功後，Inferno 會將獲取到的授權碼 (code) 交換為 access token。

      更多有關 #{title} 的資訊：

      * [Standalone Launch Sequence](https://www.hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
    )

    config(
      inputs: {
        client_id: {
          name: :standalone_client_id,
          title: 'Standalone Client ID',
          description: 'Client ID provided during registration of Inferno as a standalone application'
        },
        client_secret: {
          name: :standalone_client_secret,
          title: 'Standalone Client Secret',
          description: 'Client Secret provided during registration of Inferno as a standalone application. ' \
                       'Only for clients using confidential symmetric authentication.'
        },
        requested_scopes: {
          name: :standalone_requested_scopes,
          title: 'Standalone Scope',
          description: 'OAuth 2.0 scope provided by system to enable all required functionality',
          type: 'textarea',
          default: 'launch/patient openid fhirUser offline_access patient/*.read'
        },
        url: {
          title: 'Standalone FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications'
        },
        code: {
          name: :standalone_code
        },
        state: {
          name: :standalone_state
        },
        smart_credentials: {
          name: :standalone_smart_credentials
        },
        standalone_tls_mode: {
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
        code: { name: :standalone_code },
        token_retrieval_time: { name: :standalone_token_retrieval_time },
        state: { name: :standalone_state },
        id_token: { name: :standalone_id_token },
        refresh_token: { name: :standalone_refresh_token },
        access_token: { name: :standalone_access_token },
        expires_in: { name: :standalone_expires_in },
        patient_id: { name: :standalone_patient_id },
        encounter_id: { name: :standalone_encounter_id },
        received_scopes: { name: :standalone_received_scopes },
        intent: { name: :standalone_intent },
        smart_credentials: { name: :standalone_smart_credentials }
        standalone_tls_mode: -> { input('standalone_tls_mode') == 'true' }
      },
      requests: {
        redirect: { name: :standalone_redirect },
        token: { name: :standalone_token }
      }
    )

    input_order :url,
                :standalone_client_id,
                :standalone_client_secret,
                :standalone_requested_scopes
                :standalone_tls_mode

    test from: :tls_version_test,
         id: :standalone_auth_tls,
         title: 'OAuth 2.0 authorize endpoint secured by transport layer security',
         description: %(
           應用程式必須確保敏感資訊（authentication secrets、
           authorization codes、tokens）只能透過 TLS 加密通道傳輸至已驗證的伺服器，以確保安全性。
         ),
         config: {
           inputs: { url: { name: :smart_authorization_url } },
           options: {  minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
         }
    test from: :smart_app_redirect
    test from: :smart_code_received
    if config.options[:standalone_tls_mode]&.call == true
      test from: :tls_version_test,
          id: :standalone_token_tls,
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
