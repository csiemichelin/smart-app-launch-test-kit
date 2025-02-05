require_relative 'token_refresh_test'

module SMARTAppLaunch
  class TokenRefreshSTU2Test < TokenRefreshTest
    include TokenPayloadValidation

    id :smart_token_refresh_stu2
    title 'Server successfully refreshes the access token when optional scope parameter omitted'
    description %(
      伺服器應該要能夠與 OAuth token 端點成功交換 refresh token，且請求的 body 不需要提供 scope。
      雖然 SMART App Launch Guide 並未強制要求 refresh token 交換時包含 Cache-Control 的 header，但為了與 access token 交換的要求保持一致，回應應該包含 `Cache-Control: no-store` 和 `Pragma: no-cache`，以確保敏感資訊不會被快取。
    )
    input :client_auth_type, :client_secret
    input :client_auth_encryption_method, optional: true
    # input :client_secret, optional: true

    def add_credentials_to_request(oauth2_headers, oauth2_params)
      case client_auth_type
      when 'public'
        oauth2_params['client_id'] = client_id
      when 'confidential_symmetric'
        assert client_secret.present?,
               "A client secret must be provided when using confidential symmetric client authentication."

        credentials = Base64.strict_encode64("#{client_id}:#{client_secret}")
        oauth2_headers['Authorization'] = "Basic #{credentials}"
      when 'confidential_asymmetric'
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
