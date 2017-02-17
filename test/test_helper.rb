require 'minitest/autorun'
require 'moirai'

SAMPLE_CONFIG_FILE_PATH = "#{File.dirname(__FILE__)}/sample_config.yml"

class MyWorker
  include Moirai::Worker

  attr_accessor :args

  def initialize(args = nil)
    args ||= {}

    self.args = args
  end
end