module FeedTools
  # Injects support for caching of feed data
  module Caching
    def self.included(base)
      base.extend ClassMethods
      base.extend FeedTools::Memoize
      base.send :attr_accessor, :cache
    end

    module ClassMethods
      # Declares that the passed attributes should be memoized and stored
      # in the feed cache
      def cache(*names)
        names.each do |name|
          class_eval %{
            def #{name}_with_caching
              returning #{name}_without_caching do |value|
                self.cache.#{name} = value if self.cache
              end
            end
            
            def #{name}_with_caching=(value)
              self.#{name}_without_caching = value
              self.cache.#{name} = value if self.cache
            end
          }
          unless instance_methods.include?("#{name}=")
            attr_writer :"#{name}"
          end
          alias_method_chain name, :caching
          alias_method_chain :"#{name}=", :caching
          memoize name
        end
      end
    end
  end
end