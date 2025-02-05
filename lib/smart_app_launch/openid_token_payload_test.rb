require_relative 'token_payload_validation'

module SMARTAppLaunch
  class OpenIDTokenPayloadTest < Inferno::Test
    include TokenPayloadValidation
    id :smart_openid_token_payload
    title 'ID token payload has required claims and a valid signature'
    description %(
      ID token 必須包含以下欄位：`iss`、`sub`、`aud`、`exp`、`iat`。
      另外需符合以下規則：

      - `iss` 必須與 OpenID Connect .well-known 設定中的 `issuer` 相同。
      - `aud` 必須與 client ID 匹配。
      - `exp` 必須是未來的時間。
      - `sub` 必須是非空字串，且長度不能超過 255 個字元。
    )

    REQUIRED_CLAIMS = ['iss', 'sub', 'aud', 'exp', 'iat'].freeze

    def required_claims
      REQUIRED_CLAIMS.dup
    end

    input :id_token,
          :openid_configuration_json,
          :id_token_jwk_json,
          :client_id

    run do
      skip_if id_token.blank?, 'No ID Token'
      skip_if openid_configuration_json.blank?, 'No OpenID Configuration found'
      skip_if id_token_jwk_json.blank?, 'No ID Token jwk found'
      skip_if client_id.blank?, 'No Client ID'

      begin
        configuration = JSON.parse(openid_configuration_json)
        jwk = JSON.parse(id_token_jwk_json).deep_symbolize_keys
        payload, =
          JWT.decode(
            id_token,
            JWT::JWK.import(jwk).public_key,
            true,
            algorithms: ['RS256'],
            exp_leeway: 60,
            iss: configuration['issuer'],
            aud: client_id,
            verify_not_before: false,
            verify_iat: false,
            verify_jti: false,
            verify_sub: true,
            verify_iss: true,
            verify_aud: true
          )
      rescue StandardError => e
        assert false, "Token validation error: #{e.message}"
      end

      sub_value = payload['sub']
      assert !sub_value.blank?, "ID token `sub` claim is blank"
      assert sub_value.length < 256, "ID token `sub` claim exceeds 255 characters in length"

      missing_claims = required_claims - payload.keys
      missing_claims_string = missing_claims.map { |claim| "`#{claim}`" }.join(', ')

      assert missing_claims.empty?, "ID token missing required claims: #{missing_claims_string}"
    end
  end
end
