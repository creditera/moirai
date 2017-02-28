require "test_helper"

class TestMoiraiConfiguration < MiniTest::Test

  def test_configure_sets_nsqlookupd
    config_hash = {
      globals: {
        nsqlookupd: "127.0.0.1:4161"
      },
      health_check: {
        port: 3150,
        "rack-handler": "puma"
      },
      workers: [
        worker_class_name: "MemberCreatedAnalyticsWorker",
        count: 1,
        args: {
          topic: "ALS-MEM-created",
          channel: "moirai-analytics-worker",
          nsqlookupd: "172.29.1.78:4161"
        }
      ]
    }

    Moirai.configure do |config|
      config.globals = config_hash[:globals]
      config.health_check = config_hash[:health_check]
      config.workers = config_hash[:workers]
    end

    configuration = Moirai.configuration
    assert configuration.workers.count == 1
    assert_equal "127.0.0.1:4161", configuration[:nsqlookupd]
  end

end
