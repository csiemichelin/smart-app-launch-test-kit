require 'uri'
require_relative 'app_redirect_test'

module SMARTAppLaunch
  class AppRedirectTestSTU2 < AppRedirectTest
    id :smart_app_redirect_stu2
    description %(
      OAuth 伺服器會將用戶端瀏覽器重導向至用戶端應用程式的 Redirect URI，以符合 SMART 授權流程的規範。

      客戶端必須使用 HTTP GET 或 HTTP POST 方法向授權伺服器發送授權請求，進行授權碼交換([Authorization Code
      Request](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#request-4))。
    )

    input :authorization_method,
          title: 'Authorization Request Method',
          type: 'radio',
          default: 'get',
          options: {
            list_options: [
              {
                label: 'GET',
                value: 'get'
              },
              {
                label: 'POST',
                value: 'post'
              }
            ]
          }

    def authorization_url_builder(url, params)
      return super if authorization_method == 'get'

      post_params = params.merge(auth_url: url)

      post_url = URI(config.options[:post_authorization_uri])
      post_url.query = URI.encode_www_form(post_params)
      post_url.to_s
    end
  end
end
