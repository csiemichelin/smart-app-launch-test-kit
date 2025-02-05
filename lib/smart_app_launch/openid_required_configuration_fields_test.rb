module SMARTAppLaunch
  class OpenIDRequiredConfigurationFieldsTest < Inferno::Test
    id :smart_openid_required_configuration_fields
    title 'OpenID Connect well-known configuration contains all required fields'
    description %(
      確認 OpenID Connect 設定包含以下必要欄位：`issuer`、`authorization_endpoint`、`token_endpoint`、`jwks_uri`、`response_types_supported`、`subject_types_supported`、`id_token_signing_alg_values_supported`。

      另外，[SMART App Launch
      Framework](https://www.hl7.org/fhir/smart-app-launch/1.0.0/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
      要求必須支援 RSA SHA-256 簽名演算法。
    )

    input :openid_configuration_json
    output :openid_jwks_uri

    REQUIRED_FIELDS =
      [
        'issuer',
        'authorization_endpoint',
        'token_endpoint',
        'jwks_uri',
        'response_types_supported',
        'subject_types_supported',
        'id_token_signing_alg_values_supported'
      ].freeze

    def required_fields
      REQUIRED_FIELDS.dup
    end

    run do
      skip_if openid_configuration_json.blank?

      configuration = JSON.parse(openid_configuration_json)
      output openid_jwks_uri: configuration['jwks_uri']

      missing_fields = required_fields - configuration.keys
      missing_fields_string = missing_fields.map { |field| "`#{field}`" }.join(', ')

      assert missing_fields.empty?,
             "OpenID Connect well-known configuration missing required fields: #{missing_fields_string}"

      assert configuration['id_token_signing_alg_values_supported'].include?('RS256'),
             'Signing tokens with RSA SHA-256 not supported'
    end
  end
end
