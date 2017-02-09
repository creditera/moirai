module Moirai
  module Utils
    module_function

    def symbolize_hash_keys(hash)
      hash.each_with_object({}) do |symbolized_hash, (key, val)|
        symbolized_hash[key.to_sym] = val
      end
    end
  end
end