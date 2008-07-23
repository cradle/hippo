module FeedTools
  class Feed
    include FeedTools::Processing
    include FeedTools::Caching
    include FeedTools::Sanitize

    attr_writer :title, :subtitle, :links, :entries, :feed_type,
      :feed_version, :guid, :href, :feed_data_type

    def title
      title_node = try_xpaths(channel_node, %w[atom10:title atom03:title
                                               atom:title title dc:title
                                               channelTitle TITLE])
      process_text_and_strip_wrapper(title_node)
    end

    def subtitle
      subtitle_node = try_xpaths(channel_node,
        %w[atom10:subtitle subtitle atom03:tagline tagline description summary
           abstract ABSTRACT content:encoded encoded content xhtml:body body
           xhtml:div div p:payload payload channelDescription blurb info])
      process_text_and_strip_wrapper(subtitle_node) || itunes_summary || itunes_subtitle
    end

    def itunes_summary
      value = try_xpaths([channel_node, root_node],
                        %w{itunes:summary/text()},
                        :select_result_value => true)
      unescape_and_sanitize(value)
    end

    def itunes_subtitle
      value = try_xpaths([channel_node, root_node],
                        %w{itunes:subtitle/text()},
                        :select_result_value => true)
      unescape_and_sanitize(value)
    end

    def itunes_author
      unescape(try_xpaths(channel_node,
                          %w{itunes:author/text()},
                          :select_result_value => true))
    end

    def media_text
      value = try_xpaths([channel_node, root_node],
                        %w{media:text/text()},
                        :select_result_value => true)
      unescape_and_sanitize(value)
    end

    def time
      value = try_xpaths(channel_node, %w{
        atom10:updated/text() atom03:updated/text() atom:updated/text()
        updated/text() atom10:modified/text() atom03:modified/text()
        atom:modified/text() modified/text() time/text()
        lastBuildDate/text() atom10:issued/text() atom03:issued/text()
        atom:issued/text() issued/text() atom10:published/text()
        atom03:published/text() atom:published/text() published/text()
        dc:date/text() pubDate/text() date/text()},
        :select_result_value => true)

      Time.parse(value).gmtime rescue Time.now.gmtime
    end

    def updated
      value = try_xpaths(channel_node, %w{
        atom10:updated/text() atom03:updated/text() atom:updated/text()
        updated/text() atom10:modified/text() atom03:modified/text()
        atom:modified/text() modified/text() lastBuildDate/text()},
        :select_result_value => true)

      Time.parse(value).gmtime rescue nil
    end

    def published
      value = try_xpaths(channel_node, %w{
        atom10:published/text() atom03:published/text() atom:published/text()
        published/text() dc:date/text() pubDate/text() atom10:issued/text()
        atom03:issued/text() atom:issued/text() issued/text()},
        :select_result_value => true)
      
      Time.parse(value).gmtime rescue nil
    end
    
    def feed_data_type
      :xml
    end
    
    def http_headers
      cache && cache.http_headers ? cache.http_headers
    end

    cache :title, :href, :link, :feed_data_type, :last_retrieved,
          :feed_data, :http_headers, :time_to_live

    memoize :subtitle, :itunes_summary, :itunes_subtitle, :itunes_author,
            :time, :updated, :published

    alias_method :url, :href
    alias_method :url=, :href=
    alias_method :tagline, :subtitle
    alias_method :tagline=, :subtitle=
    alias_method :description, :subtitle
    alias_method :description=, :subtitle=
    alias_method :abstract, :subtitle
    alias_method :abstract=, :subtitle=
    alias_method :copyright, :rights
    alias_method :copyright=, :rights=
    alias_method :ttl, :time_to_live
    alias_method :ttl=, :time_to_live=
    alias_method :id, :guid
    alias_method :id=, :guid=
    alias_method :items, :entries
    alias_method :items=, :entries=
  end
end