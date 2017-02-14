require_relative "./lib/moirai"

class MyWorker
  include Moirai::Worker
  
  def setup
    p "Getting things ready for work..."
  end
  
  def work
    p "I'm working on it!"
    
    sleep 1
  end
  
  def teardown
    p "Cleaning up my mess!"
  end
end

class MyWorker2
  include Moirai::Worker
  
  def setup
    p "Getting things ready for work..."
  end
  
  def work
    p "I'm working on it!"
    
    sleep 1
  end
  
  def teardown
    p "Cleaning up my mess!"
  end
end

manager = Moirai::WorkerManager.new(
  worker_class_name: "MyWorker",
  count: 2
)
manager2 = Moirai::WorkerManager.new(
  worker_class_name: "MyWorker2",
  count: 3
)

supervisor = Moirai::Supervisor.new
supervisor.add_manager manager
supervisor.add_manager manager2
supervisor.start