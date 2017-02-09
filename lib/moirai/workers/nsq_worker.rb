module Moirai
  module NsqWorker
    include Moirai::Worker

    attr_accessor :consumer, :consumer_args

    def initialize(options = nil)
      options ||= {}
      merged_consumer_args = nsq_defaults.merge options

      self.consumer_args = merged_consumer_args
    end

    def nsq_defaults
      {
        nsqd: "127.0.0.1:4150",
        max_in_flight: 2
      }
    end

    def default_consumer
      # Set up NSQ Consumer
      Nsq::Consumer.new consumer_args
    end

    def setup
      self.consumer = default_consumer
    end

    def work
      message = consumer.pop

      process message
    end

    # If you don't override this method and finish the message,
    # all of this queue's messages will be pulled and then timeout/requeue
    def process(message); end

    def teardown
      consumer.terminate
    end
  end
end