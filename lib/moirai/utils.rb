module Moirai
  module Utils
    module_function

    def symbolize_hash_keys(hash)
      hash.reduce({}) do |symbolized_hash, (key, val)|
        symbolized_hash[key.to_sym] = val

        symbolized_hash
      end
    end
  end
end