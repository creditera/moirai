module Moirai
  class WorkerManager
    attr_accessor :worker_class_name, :worker_class, :count, :threads, :args, :threads_reaped

    def initialize(worker_class_name:, count:, args: nil)
      self.worker_class_name = worker_class_name
      self.worker_class = Object.const_get worker_class_name
      self.threads_reaped = 0
      self.count = count
      self.args = args
      self.threads = []
    end

    def report_health
      {
        worker_class_name: worker_class_name,
        count: count,
        workers_reaped: threads_reaped,
        workers: worker_statuses
      }
    end

    def worker_statuses
      threads.map do |thread|
        status = thread.status
        alive_since = thread[:alive_since]
        alive_since = "N/A" unless status

        {
          status: thread.status,
          alive_since: alive_since,
          worker_args: args
        }
      end
    end

    def new_instance    
      if args
        worker_class.new args
      else
        worker_class.new
      end
    end

    def living_workers
      threads.select(&:alive?)
    end

    def dead_workers
      threads.reject(&:alive?)
    end

    def add_worker_thread
      threads << Thread.new do
        worker = new_instance
        Thread.current[:worker] = worker
        Thread.current[:alive_since] = Time.now.utc.to_s
        worker.start
      end
    end

    def setup_workers
      start_new_workers
    end

    def cleanup_workers
      dead_workers.each do |thread|
        stop_worker_thread thread
        threads.delete thread
      end
    end

    def stop_worker_thread(thread)
      worker = thread[:worker]
      worker.stop if worker

      thread.exit
      thread.join

      self.threads_reaped += 1
    end

    def start_new_workers
      # This used to be a while loop,
      # but it incurred an immediate performance hit,
      # so we're doing this now
      threads_to_add = count - threads.size

      threads_to_add.times { add_worker_thread }
    end

    def stop
      threads.each do |thread|
        stop_worker_thread thread
      end
    end
  end
end
