module SMARTAppLaunch
  class LaunchReceivedTest < Inferno::Test
    title 'EHR server sends launch parameter'
    description %(
      `launch` URL 參數用來將應用程式的授權請求與當前的 EHR session 關聯起來。
    )
    id :smart_launch_received

    output :launch
    uses_request :launch

    run do
      launch = request.query_parameters['launch']
      output launch: launch

      assert launch.present?, 'No `launch` parameter received'
    end
  end
end
