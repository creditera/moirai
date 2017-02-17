module Moirai
  class RackHealth
    HEALTH_CHECK_PATH = "/nav_health"
    HEALTH_STATUSES = %w(allgood ruhroh sonofa)
    HEALTHY = 0
    WARNING = 1
    ERROR = 2

    def initialize(supervisor)
      @supervisor = supervisor
    end

    def call(env)
      path = env['REQUEST_PATH'] || env['PATH_INFO']

      if path == HEALTH_CHECK_PATH
        http_status = 200

        headers = { "Content-Type" => "application/json" }

        status = HEALTH_STATUSES[HEALTHY]

        component_checks = manager_checks

        body = {
          hostname: Socket.gethostname,
          time: Time.now.utc.to_s,
          ts: Time.now.to_f,
          status: status,
          components: component_checks
        }

        http_status = 500 if status == HEALTH_STATUSES[ERROR]

        [http_status, headers, [body.to_json]]
      else
        blank_response
      end
    end

    def blank_response
      [200, {}, []]
    end

    def manager_checks
      if @supervisor
        @supervisor.managers.map(&:report_health)
      else
        []
      end
    end
  end
end