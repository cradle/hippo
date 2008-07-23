module FeedTools
  module Memoize
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def memoize(*names)
        names.each do |name|
          class_eval %{
            def #{name}_with_memoize
              @#{name} ||= #{name}_without_memoize
            end
          }
          alias_method_chain name, :memoize
        end
      end
    end
  end
end