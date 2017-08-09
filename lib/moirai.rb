require "bundler"
Bundler.require

require "rack"
require "yaml"
require "nsq"
require "singleton"

require_relative "./moirai/version"
require_relative "./moirai/utils"
require_relative "./moirai/worker_manager"
require_relative "./moirai/rack_health"
require_relative "./moirai/supervisor"
require_relative "./moirai/worker"
require_relative "./moirai/workers/nsq_worker"
require_relative "./moirai/mixins/request_store"
require_relative "./moirai/configuration"

module Moirai
  class << self
    attr_writer :configuration
  end

  def self.configuration
    Configuration.instance
  end

  def self.configure
    yield(configuration)
  end


end
