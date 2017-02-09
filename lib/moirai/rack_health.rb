module Moirai
  class RackHealth
    def call(env)
      ['200', {}, ["{ 'foo': 'bar' }"]]
    end
  end
end