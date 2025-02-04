require_relative 'app_redirect_test_stu2'
require_relative 'ehr_launch_group'
require_relative 'token_exchange_stu2_test'

module SMARTAppLaunch
  class EHRLaunchGroupSTU2 < EHRLaunchGroup
    id :smart_ehr_launch_stu2
    title 'SMART EHR Launch With Practitioner Scope'
    short_description 'Demonstrate the ability to authorize an app using the EHR Launch.'

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
        use_pkce: {
          default: 'true',
          locked: true
        },
        pkce_code_challenge_method: {
          default: 'S256',
          locked: true
        },
        requested_scopes: {
          default: 'launch openid fhirUser offline_access user/*.rs'
        }
      }
    )

    input_order :url,
                :ehr_client_id,
                :ehr_client_secret,
                :ehr_requested_scopes

    test from: :smart_app_redirect_stu2 do
      input :launch
    end

    redirect_index = children.find_index { |child| child.id.to_s.end_with? 'app_redirect' }
    children[redirect_index] = children.pop

    test from: :smart_token_exchange_stu2

    token_exchange_index = children.find_index { |child| child.id.to_s.end_with? 'token_exchange' }
    children[token_exchange_index] = children.pop

    children[token_exchange_index].id(:smart_token_exchange)
  end
end
