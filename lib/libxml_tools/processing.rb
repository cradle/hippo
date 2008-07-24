module FeedTools
  # Delegates routines that process XML to the chosen parsing framework
  module Processing
    # Attempts to find the first node matching one of the given XPath expressions
    # underneath one of the given nodes.
    def try_xpaths(nodes, paths, options={})
      FeedTools.processor.try_xpaths(nodes, paths, options)
    end

    # Finds all of the nodes matching the XPath expressions underneath any
    # of the given nodes.
    def try_xpaths_all(nodes, paths, options={})
      FeedTools.processor.try_xpaths_all(nodes, paths, options)
    end

    # Returns the root node for the document (requires #sdocument accessor)
    def root_node(options={})
      @root_node ||= FeedTools.processor.root_node(document, options)
    end

    # Shortcut for try_xpaths with :select_result_value option
    def select_value(nodes, paths, options={})
      try_xpaths(nodes, paths, options.merge(:select_result_value => true))
    end

    # Shortcut for try_xpaths_all with :select_result_value option
    def select_values(nodes, paths, options={})
      try_xpaths_all(nodes, paths, options.merge(:select_result_value => true))
    end

    # Parses an XML Document from the given string
    def parse(data)
      FeedTools.processor.parse(data)
    end

    # Determines whether the given node has the given namespace
    def has_namespace?(node, namespace)
      FeedTools.processor.has_namespace?(node, namespace)
    end

    # Extracts text element from the node and strips any wrapping element
    def process_text_and_strip_wrapper(node)
      strip_wrapper(process_text(node))
    end

    # Strips wrapping elements around the given text
    # e.g. <div> elements in an Atom feed
    def strip_wrapper(text)
      FeedTools.processor.strip_wrapper(text)
    end

    # Returns a node's content normalized as HTML
    def process_text(node)
      FeedTools.processor.process_text(node, feed_type, feed_version, [base_uri])
    end

  end
end