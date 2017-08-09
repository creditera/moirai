module Moirai
  class Configuration
    include Singleton
    extend Forwardable
    attr_accessor :health_check, :workers, :globals

    def health_check=(health_check_hash = nil)
      health_check_hash ||= {}
      @health_check = Utils.symbolize_hash_keys health_check_hash
    end

    def_delegators :@globals, :fetch, :[]
  end
end
