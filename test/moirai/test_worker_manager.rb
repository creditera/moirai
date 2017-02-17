require "test_helper"

class TestSupervisor < Minitest::Test
  def test_exists
    assert defined?(Moirai::WorkerManager)
  end

  def setup
    @worker_manager = Moirai::WorkerManager.new(
      worker_class_name: "MyWorker",
      count: 3,
      args: {
        foo: "bar"
      }
    )
  end

  def test_new_instance
    worker = @worker_manager.new_instance

    assert_equal("MyWorker", worker.class.name)
  end

  def test_add_worker_thread
    assert_equal(0, @worker_manager.threads.count)

    @worker_manager.add_worker_thread

    assert_equal(1, @worker_manager.threads.count)
  end

  def test_setup_workers
    @worker_manager.setup_workers

    assert_equal(@worker_manager.count, @worker_manager.threads.count)
  end

  def test_living_workers
    @worker_manager.setup_workers

    living_workers = @worker_manager.living_workers

    assert_equal(3, living_workers.count)
  end

  def test_dead_workers
    @worker_manager.setup_workers
    @worker_manager.stop_worker_thread(@worker_manager.threads.sample)

    dead_workers = @worker_manager.dead_workers

    assert_equal(1, dead_workers.count)
  end

  def test_stop_worker_thread
    @worker_manager.setup_workers
    @worker_manager.stop_worker_thread(@worker_manager.threads.sample)

    assert_equal(1, @worker_manager.threads_reaped)
    assert_equal(2, @worker_manager.living_workers.count)
  end

  def test_cleanup_workers
    @worker_manager.setup_workers
    @worker_manager.stop_worker_thread(@worker_manager.threads.sample)

    assert_equal(@worker_manager.threads.count - 1, @worker_manager.living_workers.count)

    @worker_manager.cleanup_workers

    assert_equal(@worker_manager.threads.count, @worker_manager.living_workers.count)
  end

  def teardown
    @worker_manager.stop
  end
end