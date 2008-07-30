#--
# Copyright (c) 2008 Sean Cribbs
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Hippo
  # Delegates routines that process XML to the chosen parsing framework
  module Processing
    # Attempts to find the first node matching one of the given XPath expressions
    # underneath one of the given nodes.
    def try_xpaths(nodes, paths, options={})
      Hippo.processor.try_xpaths(nodes, paths, options)
    end

    # Finds all of the nodes matching the XPath expressions underneath any
    # of the given nodes.
    def try_xpaths_all(nodes, paths, options={})
      Hippo.processor.try_xpaths_all(nodes, paths, options)
    end

    # Returns the root node for the document (requires #sdocument accessor)
    def root_node(options={})
      @root_node ||= Hippo.processor.root_node(document, options)
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
      Hippo.processor.parse(data)
    end

    # Determines whether the given node has the given namespace
    def has_namespace?(node, namespace)
      Hippo.processor.has_namespace?(node, namespace)
    end

    # Extracts text element from the node and strips any wrapping element
    def process_text_and_strip_wrapper(node)
      strip_wrapper(process_text(node))
    end

    # Strips wrapping elements around the given text
    # e.g. <div> elements in an Atom feed
    def strip_wrapper(text)
      Hippo.processor.strip_wrapper(text)
    end

    # Returns a node's content normalized as HTML
    def process_text(node)
      Hippo.processor.process_text(node, feed_type, feed_version, [base_uri])
    end

    # Returns the character encoding as determined by the XML processor
    def encoding_from_xml
      Hippo.processor.encoding(document)
    end
  end
end