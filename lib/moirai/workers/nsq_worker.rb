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
        max_in_flight: 2
      }
    end

    def default_consumer
      # Set up NSQ Consumer
      begin
        Nsq::Consumer.new consumer_args
      rescue Errno::ECONNREFUSED
        raise ArgumentError, nsq_not_running_message
      end
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
      # If an NSQ Worker loses or cannot form a connection
      # the consumer will not be present
      consumer.terminate if consumer
    end

    private

      def nsq_not_running_message
        "It looks like NSQ is not running at #{consumer_args[:nsqd]}! Please ensure NSQ is running and try again."
      end
  end
end