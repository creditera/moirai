require "test_helper"

class TestSupervisor < Minitest::Test
  def test_exists
    assert defined?(Moirai::Supervisor)
  end

  def test_from_file
    supervisor = Moirai::Supervisor.from_file(SAMPLE_CONFIG_FILE_PATH)

    assert_equal(1, supervisor.managers.count)
    assert_equal("MyWorker", supervisor.managers.first.worker_class_name)
    assert_equal(3, supervisor.managers.first.count)
  end

  def test_setup_managers
    config = {
      "worker_class_name" => "MyWorker",
      "count" => 5
    }

    worker_managers = Moirai::Supervisor.setup_managers([config])

    assert_equal(1, worker_managers.count)
    assert_equal("MyWorker", worker_managers.first.worker_class_name)
    assert_equal(5, worker_managers.first.count)
  end

  def test_stop
    supervisor = Moirai::Supervisor.from_file(SAMPLE_CONFIG_FILE_PATH)

    # Don't actually start the supervisor, cuz he'll block the main thread
    # and tests will stop happening :)
    supervisor.running = true

    supervisor.stop

    refute supervisor.running
  end
end