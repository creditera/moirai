module Moirai
  class Supervisor
    TERM_SIG = 0

    attr_accessor :running, :health_check_port, :rack_handler, :managers, :rack_thread

    def initialize(managers = nil, options = nil)
      managers ||= []
      options ||= {}

      @managers = managers
      @health_check_port = options.fetch(:health_check_port, 3010)
      @rack_handler = options.fetch(:rack_handler, "webrick")
      @running = false
    end

    def self.from_file(config_file)
      config_hash = Utils.symbolize_hash_keys YAML.load_file(config_file)

      from_config(config_hash)
    end

    def self.from_config(config_hash)
      Moirai.configure do |conf|
        conf.globals = config_hash[:globals]
        conf.health_check = config_hash[:health_check]
        conf.workers = config_hash[:workers]
      end

      setup_supervisor
    end

    def self.setup_supervisor
      config = Moirai.configuration

      supervisor = new

      managers = setup_managers(config.workers)

      managers.each do |manager|
        supervisor.add_manager manager
      end

      health_config = config.health_check

      supervisor.health_check_port = health_config[:port] || 3010
      supervisor.rack_handler = health_config[:rack_handler] || "webrick"

      Thread.current[:supervisor] = supervisor

      supervisor
    end

    # This method expects an array of worker config hashes
    def self.setup_managers(config)
      config.map do |worker_config|
        # This config should have, at a minimum, the following keys -
        # :worker_class_name and :count
        symbolized_config = Utils.symbolize_hash_keys worker_config

        WorkerManager.new(**symbolized_config)
      end
    end

    def start_rack_app
      @rack_thread = Thread.new(self) do |sup|
        app = Rack::Builder.new do
          run Moirai::RackHealth.new(sup)
        end.to_app

        Rack::Handler.get(rack_handler).run app, Port: health_check_port
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
      start_rack_app

      @running = true

      while running?
        monitor_workers
      end
    end

    def setup_workers
      managers.each(&:setup_workers)
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
      managers.each(&:start_new_workers)
    end

    def cleanup_workers
      managers.each(&:cleanup_workers)
    end

    def setup_traps
      trap "TERM", method(:stop)
      trap "INT", method(:stop)
    end

    def stop(signal = nil)
      signal ||= TERM_SIG
      signame = Signal.signame signal

      p [:supervisor, :stop, signame]

      @running = false

      managers.each(&:stop)

      stop_rack_app
    end
  end
end
