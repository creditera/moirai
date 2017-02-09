module Moirai
  class WorkerManager
    attr_accessor :worker_class_name, :worker_class, :count, :threads, :args

    def initialize(worker_class_name:, count:, args: nil)
      args ||= {}

      self.worker_class_name = worker_class_name
      self.worker_class = Object.const_get worker_class_name
      self.count = count
      self.args = args
      self.threads = []
    end

    def new_instance
      symbolized_args = Utils.symbolize_hash_keys args
      worker_class.new symbolized_args
    end

    def add_worker_thread
      threads << Thread.new do
        worker = new_instance
        Thread.current[:worker] = worker
        worker.start
      end
    end

    def setup_workers
      count.times { add_worker_thread }
    end

    def cleanup_workers
      threads.reject(&:alive?).each do |thread|
        stop_worker_thread thread
        threads.delete thread
      end
    end

    def stop_worker_thread(thread)
      worker = thread[:worker]
      worker.stop if worker
      thread.exit
      thread.join
    end

    def start_new_workers
      add_worker_thread while threads.size < count
    end

    def stop
      threads.each do |thread|
        stop_worker_thread thread
      end
    end
  end
end
