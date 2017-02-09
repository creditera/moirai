require "bundler"
Bundler.require

require_relative "./moirai/version"
require_relative "./moirai/utils"
require_relative "./moirai/worker_manager"
require_relative "./moirai/rack_health"
require_relative "./moirai/supervisor"

module Moirai; end
