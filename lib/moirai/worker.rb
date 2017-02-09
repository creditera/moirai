module Moirai
  module Worker
    def running?
      @running == true
    end

    def setup; end

    def start
      setup

      @running = true

      while running?
        work
      end
    end

    def work; end

    def teardown; end

    def stop
      @running = false
      
      teardown
    end
  end
end