require "rack"

module Moirai
  class Supervisor
    attr_reader :managers, :rack_thread

    def initialize(managers = nil)
      managers ||= []

      @managers = managers
      @running = false
    end

    def self.from_file(config_file)
      raw_config = YAML.load_file(config_file)

      sup = new

      raw_config["workers"].each do |worker_config|
        symbolized_config = Utils.symbolize_hash_keys worker_config

        manager = WorkerManager.new symbolized_config
        
        sup.add_manager manager
      end

      sup
    end

    def configure_health_check
      NavHealth::Check.config do |health|
        managers.each do |manager|
          health.components.add manager.worker_class_name do
            manager.threads.all?(&:alive?)
          end
        end
      end
    end

    def start_rack_app
      @rack_thread = Thread.new do
        app = Rack::Builder.new do
          use NavHealth::Middleware
          run proc { ['200', {}, []] }
        end.to_app

        Rack::Handler::WEBrick.run app, Port: 3010
      end
    end

    def stop_rack_app
      return if @rack_thread.nil?

      @rack_thread.exit
      @rack_thread.join
    end

    def add_manager(manager)
      managers << manager
    end

    def running?
      @running == true
    end

    def start
      p [:supervisor, :start, Process.pid]

      setup_traps
      setup_workers
      configure_health_check
      start_rack_app

      @running = true

      monitor_workers while running?
    end

    def setup_workers
      managers.each(&setup_workers)
    end

    def worker_threads
      managers.flat_map(&:threads)
    end

    def monitor_workers
      p [:supervisor, :monitor, "RACK:", @rack_thread.status, "WORKERS:", worker_threads.map{|t| t.status}]

      cleanup_workers
      start_new_workers

      sleep 1
    end

    def start_new_workers
      managers.each(&start_new_workers)
    end

    def cleanup_workers
      managers.each(&cleanup_workers)
    end

    def setup_traps
      trap "TERM", method(:stop)
      trap "INT", method(:stop)
    end

    def kill_random_worker(_signal = nil)
      p [:supervisor, :kill_random_worker]
      random_thread = managers.sample.threads.sample
      random_thread.exit
    end

    def stop(signal = nil)
      signame = Signal.signame signal

      p [:supervisor, :stop, signame]

      @running = false

      managers.each(&stop)

      stop_rack_app
    end
  end
end