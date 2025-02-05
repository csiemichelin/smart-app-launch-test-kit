module SMARTAppLaunch
  class WellKnownCapabilitiesSTU2Test < Inferno::Test
    title 'Well-known configuration contains required fields'
    id :well_known_capabilities_stu2
    input :well_known_configuration
    description %(
      `.well-known/smart-configuration` 這個網址回傳的 JSON 需要包含以下必填欄位：`authorization_endpoint`、`token_endpoint`、`capabilities`、`grant_types_supported` 和 `code_challenge_methods_supported`。
      如果支援 `sso-openid-connect` 功能，則 `issuer` 和 `jwks_uri` 必須存在；
      如果不支援 `sso-openid-connect`，則 `issuer` 必須省略。
    )
 
    def required_capabilities
      {
        'authorization_endpoint' => String,
        'token_endpoint' => String,
        'capabilities' => Array,
        'grant_types_supported' => Array,
        'code_challenge_methods_supported' => Array
      }
    end

    run do
      skip_if well_known_configuration.blank?, 'No well-known configuration found'
      config = JSON.parse(well_known_configuration)

      required_capabilities.each do |key, type|
        assert config.key?(key), "Well-known configuration does not include `#{key}`"
        assert config[key].present?, "Well-known configuration field `#{key}` is blank"
        assert config[key].is_a?(type), "Well-known `#{key}` must be type: #{type.to_s.downcase}"
      end

      assert config['grant_types_supported'].include?('authorization_code'),
           'Well-known `grant_types_supported` must include `authorization_code` grant type to indicate SMART App Launch Support'
      assert config['code_challenge_methods_supported'].include?('S256'),
           'Well-known `code_challenge_methods_supported` must include `S256`'
      assert config['code_challenge_methods_supported'].exclude?('plain'),
           'Well-known `code_challenge_methods_support` must not include `plain`'

      if config['capabilities'].include?('sso-openid-connect')
        assert config['issuer'].is_a?(String),
          'Well-known `issuer` field must be a string and present when server capabilities includes `sso-openid-connect`'
        assert config['jwks_uri'].is_a?(String),
          'Well-known `jwks_uri` field must be a string and present when server capabilites includes `sso-openid-coneect`'
      else
        warning do
          assert config['issuer'].nil?, 'Well-known `issuer` is omitted when server capabilites does not include `sso-openid-connect`'
        end
      end

      non_string_capabilities = config['capabilities'].reject { |capability| capability.is_a? String }

      assert non_string_capabilities.blank?, %(
        Well-known `capabilities` field must be an array of strings, but found
        non-string values:
        #{non_string_capabilities.map { |value| "`#{value.nil? ? 'nil' : value}`" }.join(', ')}
      )
    end
  end
end
