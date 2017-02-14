module Moirai
  class HealthCheckApp
    def call(env)
      path = env['REQUEST_PATH'] || env['PATH_INFO']

      if path == HEALTH_CHECK_PATH
        http_status = 200

        headers = {
          'Content-Type' => 'application/json'
        }

        status = HEALTH_STATUSES[HEALTHY]

        # If any components that the app relies on are down, the app should be down
        # if component_checks.any? { |check| check[:status] == HEALTH_STATUSES[ERROR] }
        #   status = HEALTH_STATUSES[ERROR]
        # end

        component_checks = []

        body = {
          hostname: Socket.gethostname,
          time: Time.now.utc.to_s,
          ts: Time.now.to_f,
          status: status,
          components: component_checks
        }

        http_status = 500 if body[:status] == HEALTH_STATUSES[ERROR]

        [http_status, headers, [body.to_json]]
      else
        blank_response
      end
    end

    def blank_response
      [200, {}, []]
    end
  end
end