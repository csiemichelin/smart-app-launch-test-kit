module SMARTAppLaunch
  class AppLaunchTest < Inferno::Test
    title 'EHR server redirects client browser to Inferno app launch URI'
    description %(
      EHR 伺服器會依照 SMART EHR 啟動流程，將用戶端瀏覽器導向應用程式的 launch URI。
    )
    id :smart_app_launch

    input :url
    receives_request :launch

    config options: { launch_uri: "#{Inferno::Application['base_url']}/custom/smart/launch" }

    def wait_message
      return instance_exec(&config.options[:launch_message_proc]) if config.options[:launch_message_proc].present?

      %(
        ### #{self.class.parent&.parent&.title}

        Waiting for Inferno to be launched from the EHR.

        Tests will resume once Inferno receives a launch request at
        `#{config.options[:launch_uri]}` with an `iss` of `#{url}`.
      )
    end

    run do
      wait(
        identifier: url,
        message: wait_message
      )
    end
  end
end
