module SMARTAppLaunch
  class TokenResponseHeadersTest < Inferno::Test
    title 'Response includes correct HTTP Cache-Control and Pragma headers'
    description %(
      授權伺服器的回應裡必須包含 `Cache-Control: no-store` 和 `Pragma: no-cache` 這兩個 HTTP header，確保瀏覽器或其他快取機制不會儲存這些敏感資訊。
    )
    id :smart_token_response_headers

    uses_request :token

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      cc_header = request.response_header('Cache-Control')&.value

      assert cc_header&.downcase&.include?('no-store'),
             'Token response must have `Cache-Control` header containing `no-store`.'

      pragma_header = request.response_header('Pragma')&.value

      assert pragma_header&.downcase&.include?('no-cache'),
             'Token response must have `Pragma` header containing `no-cache`.'
    end
  end
end
