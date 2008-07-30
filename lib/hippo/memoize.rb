module Hippo
  module Memoize
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
    
    def memoize_writer(*names)
      attr_writer *names
      memoize *names
    end
  end
end