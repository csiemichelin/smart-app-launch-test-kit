require_relative 'app_redirect_test_stu2'
require_relative 'token_exchange_stu2_test'
require_relative 'standalone_launch_group'

module SMARTAppLaunch
  class StandaloneLaunchGroupSTU2 < StandaloneLaunchGroup
    id :smart_standalone_launch_stu2
    title 'Standalone Launch With Patient Scope'
    short_description 'Demonstrate the ability to authorize an app using the Standalone Launch.'

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
        use_pkce: {
          default: 'true',
          locked: true
        },
        pkce_code_challenge_method: {
          default: 'S256',
          locked: true
        },
        requested_scopes: {
          default: 'launch/patient openid fhirUser offline_access patient/*.rs'
        }
      }
    )

    input_order :url,
                :standalone_client_id,
                :standalone_client_secret,
                :standalone_requested_scopes

    test from: :smart_app_redirect_stu2

    redirect_index = children.find_index { |child| child.id.to_s.end_with? 'app_redirect' }
    children[redirect_index] = children.pop

    test from: :smart_token_exchange_stu2

    token_exchange_index = children.find_index { |child| child.id.to_s.end_with? 'token_exchange' }
    children[token_exchange_index] = children.pop

    children[token_exchange_index].id('smart_token_exchange')
  end
end
