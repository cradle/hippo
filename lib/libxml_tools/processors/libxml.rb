require 'rubygems'
gem 'libxml-ruby', '>=0.8.0'
require 'libxml'

module FeedTools
  module Processors
    module Libxml
      extend self
      
      def try_xpaths(nodes, xpaths, options={})
        nodes, xpaths = Array(nodes).flatten.compact, Array(xpaths).flatten.compact
        raise ArgumentError, "You must specify a node and an XPath expression" if nodes.empty? || xpaths.empty?
        result_node = nodes.map {|node| xpaths.map {|xpath| node.find_first(xpath, FeedTools::NAMESPACES) } }.flatten.compact.first
        if options[:select_result_value] && result_node
          result_node.content
        else
          result_node
        end
      end
      
      def try_xpaths_all(nodes, xpaths, options={})
        nodes, xpaths = Array(nodes).flatten.compact, Array(xpaths).flatten.compact
        raise ArgumentError, "You must specify a node and an XPath expression" if nodes.empty? || xpaths.empty?
        results = nodes.map {|node| xpaths.map {|xpath| node.find(xpath, FeedTools::NAMESPACES) } }.flatten.compact
        if options[:select_result_value]
          results.map { |n| n.content }
        else
          results
        end
      end
      
      def root_node(document, options={})
        document.root
      end
      
      def has_namespace?(node, namespace)
        node.namespace.any? {|ns| ns.href == namespace || ns.prefix == namespace }
      end
      
      def parse(data)
        LibXML::XML::Parser.string(data).parse
      end
    end
  end
end