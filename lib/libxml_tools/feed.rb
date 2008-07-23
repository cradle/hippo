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
      value = select_value([channel_node, root_node], %w{itunes:summary/text()})
      unescape_and_sanitize(value)
    end

    def itunes_subtitle
      value = select_value([channel_node, root_node], %w{itunes:subtitle/text()})
      unescape_and_sanitize(value)
    end

    def itunes_author
      unescape(select_value(channel_node, %w{itunes:author/text()}))
    end

    def media_text
      value = select_value([channel_node, root_node], %w{media:text/text()})
      unescape_and_sanitize(value)
    end

    def time
      value = select_value(channel_node, %w{
        atom10:updated/text() atom03:updated/text() atom:updated/text()
        updated/text() atom10:modified/text() atom03:modified/text()
        atom:modified/text() modified/text() time/text()
        lastBuildDate/text() atom10:issued/text() atom03:issued/text()
        atom:issued/text() issued/text() atom10:published/text()
        atom03:published/text() atom:published/text() published/text()
        dc:date/text() pubDate/text() date/text()})

      Time.parse(value).gmtime rescue Time.now.gmtime
    end

    def updated
      value = select_value(channel_node, %w{
        atom10:updated/text() atom03:updated/text() atom:updated/text()
        updated/text() atom10:modified/text() atom03:modified/text()
        atom:modified/text() modified/text() lastBuildDate/text()})

      Time.parse(value).gmtime rescue nil
    end

    def published
      value = select_value(channel_node, %w{
        atom10:published/text() atom03:published/text() atom:published/text()
        published/text() dc:date/text() pubDate/text() atom10:issued/text()
        atom03:issued/text() atom:issued/text() issued/text()})

      Time.parse(value).gmtime rescue nil
    end

    def feed_data_type
      :xml
    end

    def feed_type
      if root_node
        case root_node.name.downcase
        when 'feed'
          'atom'
        when /^rdf/, 'rss'
          'rss'
        when 'channel'
          has_namespace?(root_node, FeedTools::NAMESPACES['rss11']) ? 'rss' : 'cdf'
        end
      else
        nil
      end
    end

    def http_headers
      cache && cache.http_headers ? cache.http_headers : {}
    end

    def time_to_live
      # TODO: scope within defaults
      syn_frequency || _ttl || schedule
    end

    def syn_frequency
      frequency = select_value(channel_node, %w{syn:updateFrequency/text()})
      if frequency
        period = select_value(channel_node, %w{syn:updatePeriod/text()})
        case period
        when 'daily'
          frequency.to_i.days
        when 'weekly'
          frequency.to_i.weeks
        when 'monthly'
          frequency.to_i.months
        when 'yearly'
          frequency.to_i.years
        else # hourly
          frequency.to_i.hours
        end
      else
        nil
      end
    end

    def _ttl
      # usually expressed in minutes
      frequency = select_value(channel_node, %w{ttl/text()})
      if frequency
        span = select_value(channel_node, %w{ttl/@span})
        # Assumes the span is a valid period method as defined by ActiveSupport
        frequency.to_i.send(span || :minutes)
      else
        nil
      end
    end

    def schedule
      days = select_value(channel_node, %w{schedule/intervaltime/@day}).to_i
      hours = select_value(channel_node, %w{schedule/intervaltime/@hour}).to_i
      minutes = select_value(channel_node, %w{schedule/intervaltime/@min}).to_i
      seconds = select_value(channel_node, %w{schedule/intervaltime/@sec}).to_i
      total = seconds + minutes.minutes + hours.hours + days.days
      total != 0 ? total : nil
    end

    def channel_node
      try_xpaths(root_node, %w{channel CHANNEL feedinfo news}) || root_node
    end
    
    cache :title, :href, :link, :feed_data_type, :last_retrieved,
          :feed_data, :http_headers, :time_to_live

    memoize :subtitle, :itunes_summary, :itunes_subtitle, :itunes_author,
            :time, :updated, :published, :feed_type, :channel_node

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