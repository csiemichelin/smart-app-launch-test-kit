module SMARTAppLaunch
  class CodeReceivedTest < Inferno::Test
    title 'OAuth server sends code parameter'
    description %(
      在 OAuth 授權流程中，當使用者成功驗證並授權後，`Code` 是 Redirect URI 上的必要查詢參數，用於後續的 Token 交換步驟。
    )
    id :smart_code_received

    output :code
    uses_request :redirect

    run do
      code = request.query_parameters['code']
      output code: code

      assert code.present?, 'No `code` parameter received'

      error = request.query_parameters['error']

      pass_if error.blank?

      error_message = "Error returned from authorization server. code: '#{error}'"
      error_description = request.query_parameters['error_description']
      error_uri = request.query_parameters['error_uri']
      error_message += ", description: '#{error_description}'" if error_description.present?
      error_message += ", uri: #{error_uri}" if error_uri.present?

      assert false, error_message
    end
  end
end
