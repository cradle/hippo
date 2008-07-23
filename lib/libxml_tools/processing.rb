module FeedTools
  # Delegates routines that process XML to the chosen parsing framework
  module Processing
    # Attempts to find the first node matching one of the given XPath expressions
    # underneath one of the given nodes.
    def try_xpaths(nodes, paths, options={})
      FeedTools.processor.try_xpaths(nodes, paths, options)
    end

    # Finds the first node under the given node that matches the given XPath expression.
    def find_node(node, path, options={})
      find_all_nodes(node, path, options).first
    end

    # Finds all nodes under the given node that match the given XPath expression.
    def find_all_nodes(node, path, options={})
      FeedTools.processor.find_all_nodes(node, path, options)
    end

    # Returns the root node for the document (requires #document accessor)
    def root_node(options={})
      FeedTools.processor.root_node(document, options)
    end

    # Returns the channel node for the document (requires #document accessor)
    def channel_node(options={})
      FeedTools.processor.channel_node(document, options)
    end

    # Parses an XML Document from the given string
    def parse(data)
      FeedTools.processor.parse(data)
    end

    def process_text_and_strip_wrapper(node)
      strip_wrapper(process_text(node))
    end

    def strip_wrapper(text)
      FeedTools.processor.strip_wrapper(text)
    end

    def process_text(node)
      FeedTools.processor.process_text(node, feed_type, feed_version, [base_uri])
    end
  end
end