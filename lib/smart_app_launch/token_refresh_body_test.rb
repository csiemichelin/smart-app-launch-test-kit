require_relative 'token_payload_validation'

module SMARTAppLaunch
  class TokenRefreshBodyTest < Inferno::Test
    include TokenPayloadValidation

    id :smart_token_refresh_body
    title 'Token refresh response contains all required fields'
    description %(
      EHR 授權伺服器在回應時，應該要回傳一個 JSON 結構，裡面包含 `access_token`，或者提供一個訊息表示授權請求被拒絕。
      其中 `access_token` 必須是 `Bearer` 類型，並且還需要包含 `expires_in`、`token_type` 和 `scope` 這些欄位。
      
      而 `scope` 的值必須是原始授權請求中核准範圍的子集，不能超出原本的授權範圍。
    )
    input :received_scopes
    output :refresh_token, :access_token, :token_retrieval_time, :expires_in, :received_scopes
    uses_request :token_refresh

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      assert_valid_json(response[:body])

      body = JSON.parse(response[:body])
      output refresh_token: body['refresh_token'] if body.key? 'refresh_token'

      required_fields = ['access_token', 'token_type', 'expires_in', 'scope']
      validate_required_fields_present(body, required_fields)

      old_received_scopes = received_scopes
      output access_token: body['access_token'],
             token_retrieval_time: Time.now.iso8601,
             expires_in: body['expires_in'],
             received_scopes: body['scope']

      validate_token_field_types(body)
      validate_token_type(body)

      validate_scope_subset(received_scopes, old_received_scopes)
    end
  end
end
