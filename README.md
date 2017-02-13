# Moirai

Moirai is a small library for managing a multi-threaded worker process, meant to run by itself or alongside an existing web process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'moirai'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install moirai

## Usage

### Supervisor
To spin up a worker process with Moirai, initialize a `Supervisor` and call `start`:

```ruby
require "moirai"

supervisor = Moirai::Supervisor.new

supervisor.start
#=> [:supervisor, :start, 23656]
#=> [:supervisor, :monitor, "RACK:", "run", "WORKERS:", []]
#=> [:supervisor, :monitor, "RACK:", "sleep", "WORKERS:", []]
#=> ...
```

With this, you have a simple worker process (currently doing no work) and a small rack app hosting a health check at `http://localhost:3010/nav_health`.

To make things a little more interesting, let's define a worker!

### Worker
To create a `Moirai`-compliant worker class, create a plain Ruby class and include the `Moirai::Worker` module.

```ruby
class MyWorker
  include Moirai::Worker
end
```

This module adds a few key pieces of functionality to the worker class, like the main worker process dependencies (`start`, `stop`, and `work`) and lifecycle hooks you can use in your worker (`setup` and `teardown`).

Let's define the `work` method and see our worker in action.

```ruby
class MyWorker
  include Moirai::Worker
  
  def work
    p "I'm working on it!"
    
    sleep 1
  end
end

MyWorker.new.start
#=> I'm working on it!
#=> I'm working on it!
#=> I'm working on it!
```

In the main process, the `Supervisor` watching your worker will call `start` on it, which will call the `work` method in a loop until the `stop` method is called on the worker.

#### Lifecycle Hooks

If you need to perform additional setup for your worker or need to clean up after it when `stop` is called, the `Moirai::Worker` module provides two lifecycle hooks to make this easy to accomplish: `setup` and `teardown`.

```ruby
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
```

The `setup` method will be called **before** beginning work, and the `teardown` method will be called **after** the worker is stopped.

### Worker Manager
The `Moirai::WorkerManager` is responsible for managing a pool of workers. It will hold the configuration for spinning up new workers when necessary, and it will monitor the health of existing workers.

```ruby
manager = Moirai::WorkerManager.new(
  worker_class_name: "MyWorker",
  count: 5
)

manager.add_worker_thread
#=> "Getting things ready for work..."
#=> "I'm working on it!"
manager.threads
#=> [#<Thread:0x007faee52e37e0@/moirai/lib/moirai/worker_manager.rb:24 sleep>]
#=> "I'm working on it!"
manager.stop
#=> "Cleaning up my mess!"
```

If your workers need configuration on initialize, the `WorkerManager` can take an additional hash of arguments to pass to the worker instance on boot.

```ruby
class ArgWorker
  include Moirai::Worker
  
  def initialize(options)
    self.cool_prop = options[:cool_prop]
  end
end

manager = Moirai::WorkerManager.new(
  worker_class_name: "ArgWorker",
  count: 5,
  args: {
    cool_prop: "rad"
  }
)
```

### The Configuration YAML
To facilitate setup and configuration, the `Moirai::Supervisor` can take a formatted YAML file.

```yaml
workers:
  - worker_class_name: ArgWorker
    count: 5
    args:
      :cool_prop: rad
```

The YAML file passed to the `Supervisor` should hold an array of configuration for the workers you're setting up. Each worker config chunk should include the class name of the worker (under `worker_class_name`) and the number of workers that should be spun up (under `count`).

Additionally, if the specified worker class requires arguments on initialize, the `args` property can be set here in the YAML file, and those properties will be forwarded to the worker being set up.

When configuring `args`, make sure the format of the keys in the YAML matches what your worker class expects, since the parameters will simply be forwarded by the `WorkerManager` to the `Worker`.

### The Health Check
Along with the worker process, `Moirai` will spin up a small rack app hosting a health check at `http://localhost:3010/nav_health`. This health check uses the [`NavHealth` gem](https://github.com/creditera/nav_health), so details around the endpoint can be found in that repo.

The health check can be configured in the YAML file passed to the supervisor by using the `health-check` key:

```yaml
health-check:
  port: 3050
  rack-handler: puma
workers:
  - worker_class_name: ArgWorker
    count: 5
    args:
      :cool_prop: rad
```

If not set, the health check config options will fall back to their defaults; `port` will default to `3010`, and `rack-handler` will default to `webrick`.

### Putting It Together
Let's see what a full `Moirai` setup looks like in action!

```yaml
# ./config/moirai.yml
health-check:
  port: 3050
  rack-handler: puma
workers:
  - worker_class_name: ArgWorker
    count: 5
    args:
      :cool_prop: rad
```

```ruby
require "moirai"

class ArgWorker
  include Moirai::Worker
  
  def initialize(options)
    self.cool_prop = options[:cool_prop]
  end
  
  def work
    p "Working on it!"
  end
end

supervisor = Moirai::Supervisor.from_file("./config/moirai.yml")
supervisor.start
```

Now you have a supervised worker process with 5 threaded copies of your `ArgWorker`! Woo!

### NSQ Workers
`Moirai` comes with a pre-defined `NsqWorker` module that you can include if you want a convenient NSQ worker process.

```ruby
require "moirai"

class MyNsqWorker
  include Moirai::NsqWorker
end
```

The `Moirai::NsqWorker` defines an initialize method that will take a hash of options from your configuration yaml. Since it's an NSQ worker, it's going to need at least a `topic` to listen on and a `channel` to consume the `topic`'s messages.

```yaml
workers:
  - worker_class_name: MyNsqWorker
    count: 2
    args:
      :topic: test
      :channel: foo
```

This will create two NSQ worker processes listening on the `test` topic, and consuming through the `foo` channel. Success!

#### Interface
The NSQ worker interface is slightly different than the standard worker interface: instead of defining a `work` method, you will need to define a `process` method that takes an NSQ message as an argument. You'll also need to call `finish` on the message when you're done with it so that it doesn't timeout and requeue.

```ruby
require "moirai"

class MyNsqWorker
  include Moirai::NsqWorker
  
  def process(message)
    # DO PROCESSING HERE
    
    message.finish
  end
end
```

We use the [NSQ Ruby](https://github.com/wistia/nsq-ruby) gem to power our NSQ workers under the hood, so any option you would pass to the `NSQ::Consumer` class in that library can be added to the configuration YAML:

```yaml
workers:
  - worker_class_name: MyNsqWorker
    count: 2
    args:
      :topic: test
      :channel: foo
      :max_in_flight: 5
      :nsqlookupd: "127.0.0.1:4161"
```