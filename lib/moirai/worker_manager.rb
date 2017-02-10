module Moirai
  class WorkerManager
    attr_accessor :worker_class_name, :worker_class, :count, :threads, :args

    def initialize(worker_class_name:, count:, args: nil)
      self.worker_class_name = worker_class_name
      self.worker_class = Object.const_get worker_class_name
      self.count = count
      self.args = args
      self.threads = []
    end

    def new_instance    
      if args
        worker_class.new args
      else
        worker_class.new
      end
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
      if worker = thread[:worker]
        worker.stop
      end
      thread.exit
      thread.join
    end

    def start_new_workers
      while threads.size < count
        add_worker_thread
      end
    end

    def stop
      threads.each do |thread|
        stop_worker_thread thread
      end
    end
  end
end
