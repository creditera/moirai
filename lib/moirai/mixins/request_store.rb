module Moirai
  module Mixins
    module RequestStore
      def with_request_store(store_seed = nil)
        store_seed ||= {}
        
        start_store
        preseed_store store_seed
        
        yield
        
        ensure
        clear_store
      end
      
      def start_store
        RequestStore.begin!
      end
      
      def preseed_store(seed = nil)
        seed ||= {}
        
        RequestStore.store.merge! seed
      end
      
      def clear_store
        RequestStore.end!
        RequestStore.clear!
      end
    end
  end
end