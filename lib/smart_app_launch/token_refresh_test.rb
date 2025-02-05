require_relative 'token_payload_validation'

module SMARTAppLaunch
  class TokenRefreshTest < Inferno::Test
    include TokenPayloadValidation

    id :smart_token_refresh
    title 'Server successfully refreshes the access token when optional scope parameter omitted'
    description %(
      伺服器應該要能夠與 OAuth token 端點成功交換 refresh token，且請求的 body 不需要提供 scope。
      雖然 SMART App Launch Guide 並未強制要求 refresh token 交換時包含 Cache-Control 的 header，但為了與 access token 交換的要求保持一致，回應應該包含 `Cache-Control: no-store` 和 `Pragma: no-cache`，以確保敏感資訊不會被快取。
    )
    input :smart_token_url, :refresh_token, :client_id, :received_scopes, :client_secret
    # input :client_secret, optional: true
    output :smart_credentials, :token_retrieval_time
    makes_request :token_refresh

    def add_credentials_to_request(oauth2_headers, oauth2_params)
      if client_secret.present?
        credentials = Base64.strict_encode64("#{client_id}:#{client_secret}")
        oauth2_headers['Authorization'] = "Basic #{credentials}"
      else
        oauth2_params['client_id'] = client_id
      end
    end

    def make_auth_token_request(smart_token_url, oauth2_params, oauth2_headers)
      post(smart_token_url, body: oauth2_params, name: :token_refresh, headers: oauth2_headers)
    end

    run do
      skip_if refresh_token.blank?

      oauth2_params = {
        'grant_type' => 'refresh_token',
        'refresh_token' => refresh_token
      }
      oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

      oauth2_params['scope'] = received_scopes if config.options[:include_scopes]

      add_credentials_to_request(oauth2_headers, oauth2_params)

      make_auth_token_request(smart_token_url, oauth2_params, oauth2_headers)

      assert_response_status(200)
      assert_valid_json(request.response_body)

      output token_retrieval_time: Time.now.iso8601

      token_response_body = JSON.parse(request.response_body)
      output smart_credentials: {
        refresh_token: token_response_body['refresh_token'].presence || refresh_token,
        access_token: token_response_body['access_token'],
        expires_in: token_response_body['expires_in'],
        client_id:,
        client_secret:,
        token_retrieval_time:,
        token_url: smart_token_url
      }.to_json
    end
  end
end
