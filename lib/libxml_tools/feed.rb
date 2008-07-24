module FeedTools
  class Feed
    include FeedTools::Processing
    include FeedTools::Caching
    include FeedTools::Sanitize
    
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
      time = syn_frequency || _ttl || schedule || FeedTools.defaults[:default_ttl]
      time >= FeedTools.defaults[:max_ttl] ? FeedTools.defaults[:max_ttl] : time
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
      total if total > 0
    end

    def channel_node
      try_xpaths(root_node, %w{channel CHANNEL feedinfo news}) || root_node
    end

    def guid
      select_value([channel_node, root_node], %w{atom10:id/text() atom03:id/text()
        atom:id/text() id/text() guid/text()})
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

    def feed_version
      if root_node
        stated_version = select_value(root_node, "@version")
        default_namespace = select_value(root_node, "@xmlns")
        case feed_type
        when 'atom'
          case default_namespace
          when FeedTools::NAMESPACES['atom10']
            1.0
          when FeedTools::NAMESPACES['atom03']
            0.3
          else
            stated_version.to_f if stated_version
          end
        when 'rss'
          case default_namespace
          when FeedTools::NAMESPACES['rss09']
            0.9
          when FeedTools::NAMESPACES['rss10']
            1.0
          when FeedTools::NAMESPACES['rss11']
            1.1
          else
            if stated_version
              case stated_version.to_f
              when 2.1, 2.01
                2.0
              else
                stated_version.to_f
              end
            end
          end
        when 'cdf'
          0.4
        when '!okay/news'
          1.0
        end
      else
        nil
      end
    end

    def language
      value = select_value(channel_node, %w{language/text() dc:language/text()
          @dc:language @xml:lang xml:lang/text()}) ||
        select_value(root_node, %w{@xml:lang xml:lang/text()}) ||
        'en-us'
      value.gsub(/_/, '-').downcase.sub(/^(\w+)-(\w+)$/) { "#{$1}-#{$2.upcase}" }
    end

    def explicit
      select_value(channel_node, %w{media:adult/text() itunes:explicit/text()}) =~ /true|yes/
    end

    def last_retrieved
      cache.last_retrieved if cache
    end

    def cloud
      returning FeedTools::Cloud.new do |c|
        c.domain = select_value(channel_node, 'cloud/@domain')
        c.port = select_value(channel_node, 'cloud/@port')
        c.path = select_value(channel_node, 'cloud/@path')
        c.register_procedure = select_value(channel_node, 'cloud/@registerProcedure')
        c.protocol = select_value(channel_node, 'cloud/@protocol')
        c.protocol.downcase! if c.protocol
        c.port = c.port.to_s.to_i
        c.port = nil if c.port == 0
      end
    end

    attr_writer :title, :subtitle, :links, :entries, :feed_type,
      :feed_version, :guid, :href, :feed_data_type, :last_retrieved, :cloud

    cache :title, :href, :link, :feed_data_type, :last_retrieved
          :feed_data, :http_headers, :time_to_live

    memoize :subtitle, :itunes_summary, :itunes_subtitle, :itunes_author,
            :time, :updated, :published, :feed_type, :channel_node, :guid, 
            :language, :explicit, :cloud

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
    alias_method :explicit? :explicit
  end
end