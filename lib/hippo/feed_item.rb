module Hippo
  class FeedItem
    include Hippo::Processing
    include Hippo::Sanitize
    include Hippo::URLs
    include Hippo::Memoize

    attr_accessor :feed, :root_node

    def document
      feed.document
    end

    def feed_type
      feed.feed_type
    end

    def feed_data_type
      feed.feed_data_type
    end

    def feed_version
      feed.feed_version
    end

    def encoding
      feed.encoding
    end

    def guid
      select_value(root_node, %w{
        atom10:id/@gr:original-id atom03:id/@gr:original-id
        atom:id/@gr:original-id id/@gr:original-id atom10:id/text()
        atom03:id/text() atom:id/text() id/text() guid/text()})
    end
    memoize_writer :guid

    def title
      title_node = try_xpaths(root_node, %w{atom10:title atom03:title
        atom:title title dc:title headline})
      value = process_text_and_strip_wrapper(title_node)
      value.gsub!(/\[\d*\]\s*$/, '').strip! if Hippo.defaults[:strip_comment_count]
      value
    end
    memoize_writer :title

    def content
      content_node = try_xpaths(root_node, %w{atom10:content atom03:content
        atom:content body/datacontent xhtml:body body xhtml:div div p:payload
        payload content:encoded content fullitem encoded description tagline
        subtitle atom10:summary atom03:summary atom:summary summary abstract
        blurb info})
      process_text_and_strip_wrapper(content_node) || media_text ||
        itunes_summary || itunes_subtitle
    end
    memoize_writer :content

    def summary
      summary_node = try_xpaths(root_node, %w{atom10:summary atom03:summary
        atom:summary summary abstract blurb description tagline subtitle
        xhtml:body body xhtml:div div p:payload payload fullitem
        content:encoded encoded atom10:content atom03:content atom:content
        content info body/datacontent})
      process_text_and_strip_wrapper(summary_node) || media_text ||
          itunes_summary || itunes_subtitle
    end
    memoize_writer :summary

    def links
      link_objects = try_xpaths_all(root_node, %w{atom10:link atom03:link
          atom:link link a url href}).map do |node|
            returning Hippo::Link.new do |l|
              l.parse(node, feed)
            end
        end
      # If no links found, but an enclosure, make that enclosure the first link
      if link_objects.empty? && enclosures.first
        link_objects << Hippo::Link.new(enclosures.first.href, nil, nil, enclosures.first.type)
      end
      link_objects
    end
    memoize_writer :links

    def link
      if links.empty?
        nil
      else
        links.max {|l| l.rank(feed) }.href
      end
    end
    memoize_writer :link
    
    alias_method :abstract, :summary
    alias_method :abstract=, :summary=
    alias_method :description, :summary
    alias_method :description=, :summary=
    alias_method :copyright, :rights
    alias_method :copyright=, :rights=
    alias_method :id, :guid
    alias_method :id=, :guid=
  end
end