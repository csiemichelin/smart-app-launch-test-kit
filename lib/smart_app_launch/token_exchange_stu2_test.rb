require_relative 'client_assertion_builder'
require_relative 'token_exchange_test'

module SMARTAppLaunch
  class TokenExchangeSTU2Test < TokenExchangeTest
    title 'OAuth token exchange request succeeds when supplied correct information'
    description %(
      當應用程式拿到授權代碼後，它會透過 HTTP POST 請求，把授權代碼傳送到 EHR 授權伺服器的 token 端點，並交換取得 access token。這個過程會使用 `application/x-www-form-urlencoded` 的格式，並遵守 OAuth 2.0 的標準和 [4.1.3 of
      RFC6749](https://tools.ietf.org/html/rfc6749#section-4.1.3) 中的標準規範，確保授權和 token 交換過程是安全的。
    )
    id :smart_token_exchange_stu2

    input :client_auth_encryption_method,
      title: 'Encryption Method (Confidential Asymmetric Client Auth Only)',
      type: 'radio',
      default: 'ES384',
      options: {
        list_options: [
          {
            label: 'ES384',
            value: 'ES384'
          },
          {
            label: 'RS384',
            value: 'RS384'
          }
        ]
      }

    input :client_auth_type,
          title: 'Client Authentication Method',
          type: 'radio',
          default: 'public',
          options: {
            list_options: [
              {
                label: 'Public',
                value: 'public'
              },
              {
                label: 'Confidential Symmetric',
                value: 'confidential_symmetric'
              },
              {
                label: 'Confidential Asymmetric',
                value: 'confidential_asymmetric'
              }
            ]
          }

    config(
      inputs: {
        use_pkce: {
          default: 'true',
          options: {
            list_options: [
              {
                label: 'Enabled',
                value: 'true'
              }
            ]
          }
        }
      }
    )

    def add_credentials_to_request(oauth2_params, oauth2_headers)
      if client_auth_type == 'confidential_symmetric'
        assert client_secret.present?,
               "A client secret must be provided when using confidential symmetric client authentication."

        client_credentials = "#{client_id}:#{client_secret}"
        oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
      elsif client_auth_type == 'public'
        oauth2_params[:client_id] = client_id
      else
        oauth2_params.merge!(
          client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
          client_assertion: ClientAssertionBuilder.build(
            iss: client_id,
            sub: client_id,
            aud: smart_token_url,
            client_auth_encryption_method: client_auth_encryption_method
          )
        )
      end
    end
  end
end
