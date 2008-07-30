module Hippo
  class Feed
    include Hippo::Processing
    include Hippo::Caching
    include Hippo::Sanitize
    include Hippo::URLs
    
    def title
      title_node = try_xpaths(channel_node, %w{atom10:title atom03:title
                                               atom:title title dc:title
                                               channelTitle TITLE})
      process_text_and_strip_wrapper(title_node)
    end
    cache :title
    
    def subtitle
      subtitle_node = try_xpaths(channel_node,
        %w{atom10:subtitle subtitle atom03:tagline tagline description summary
           abstract ABSTRACT content:encoded encoded content xhtml:body body
           xhtml:div div p:payload payload channelDescription blurb info})
      process_text_and_strip_wrapper(subtitle_node) || itunes_summary || itunes_subtitle
    end
    memoize_writer :subtitle
    
    def itunes_summary
      value = select_value([channel_node, root_node], %w{itunes:summary/text()})
      unescape_and_sanitize(value)
    end
    memoize_writer :itunes_summary
    
    def itunes_subtitle
      value = select_value([channel_node, root_node], %w{itunes:subtitle/text()})
      unescape_and_sanitize(value)
    end
    memoize_writer :itunes_subtitle
    
    def itunes_author
      unescape(select_value(channel_node, %w{itunes:author/text()}))
    end
    memoize_writer :itunes_author
    
    def media_text
      value = select_value([channel_node, root_node], %w{media:text/text()})
      unescape_and_sanitize(value)
    end
    memoize_writer :media_text
    
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
    memoize_writer :time
    
    def updated
      value = select_value(channel_node, %w{
        atom10:updated/text() atom03:updated/text() atom:updated/text()
        updated/text() atom10:modified/text() atom03:modified/text()
        atom:modified/text() modified/text() lastBuildDate/text()})

      Time.parse(value).gmtime rescue nil
    end
    memoize_writer :updated
    
    def published
      value = select_value(channel_node, %w{
        atom10:published/text() atom03:published/text() atom:published/text()
        published/text() dc:date/text() pubDate/text() atom10:issued/text()
        atom03:issued/text() atom:issued/text() issued/text()})

      Time.parse(value).gmtime rescue nil
    end
    memoize_writer :published
    
    def feed_data_type
      :xml
    end
    cache :feed_data_type
    
    def feed_type
      if root_node
        case root_node.name.downcase
        when 'feed'
          'atom'
        when /^rdf/, 'rss'
          'rss'
        when 'channel'
          has_namespace?(root_node, Hippo::NAMESPACES['rss11']) ? 'rss' : 'cdf'
        end
      else
        nil
      end
    end
    memoize_writer :feed_type
    
    def http_headers
      cache && cache.http_headers ? cache.http_headers : {}
    end
    cache :http_headers
    
    def time_to_live
      time = syn_frequency || _ttl || schedule || Hippo.defaults[:default_ttl]
      time >= Hippo.defaults[:max_ttl] ? Hippo.defaults[:max_ttl] : time
    end
    memoize_writer :time_to_live
    
    def channel_node
      try_xpaths(root_node, %w{channel CHANNEL feedinfo news}) || root_node
    end
    memoize_writer :channel_node
    
    def guid
      select_value([channel_node, root_node], %w{atom10:id/text() atom03:id/text()
        atom:id/text() id/text() guid/text()})
    end
    memoize_writer :guid

    def feed_version
      if root_node
        stated_version = select_value(root_node, "@version")
        default_namespace = select_value(root_node, "@xmlns")
        case feed_type
        when 'atom'
          case default_namespace
          when Hippo::NAMESPACES['atom10']
            1.0
          when Hippo::NAMESPACES['atom03']
            0.3
          else
            stated_version.to_f if stated_version
          end
        when 'rss'
          case default_namespace
          when Hippo::NAMESPACES['rss09']
            0.9
          when Hippo::NAMESPACES['rss10']
            1.0
          when Hippo::NAMESPACES['rss11']
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
    memoize_writer :feed_version
    
    def language
      value = select_value(channel_node, %w{language/text() dc:language/text()
          @dc:language @xml:lang xml:lang/text()}) ||
        select_value(root_node, %w{@xml:lang xml:lang/text()}) ||
        'en-us'
      value.gsub(/_/, '-').downcase.sub(/^(\w+)-(\w+)$/) { "#{$1}-#{$2.upcase}" }
    end
    memoize_writer :language
    
    def explicit
      select_value(channel_node, %w{media:adult/text() itunes:explicit/text()}) =~ /true|yes/
    end
    memoize_writer :explicit
    
    def last_retrieved
      cache.last_retrieved if cache
    end
    cache :last_retrieved
    
    def cloud
      returning Hippo::Cloud.new do |c|
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
    memoize_writer :cloud
    
    def encoding
      @encoding ||= if http_headers && http_headers['content-type'] =~ /charset=([\w\d-]+)/
        $1.downcase
      else
        encoding_from_xml
      end
    end
    memoize_writer :encoding
    
    def feed_data
      cache.feed_data if cache
    end
    cache :feed_data
    
    def document
      parse(feed_data)
    end
    memoize_writer :document
    
    def rights
      process_text_and_strip_wrapper(try_xpaths(channel_node, %w{
        atom10:copyright atom03:copyright atom:copyright copyright
        copyrights dc:rights rights}))
    end
    memoize_writer :rights
    
    def images
      try_xpaths_all(channel_node, %w{image logo apple-wallpapers:image 
        imageUrl}).map do |node|
          # TODO: Massage href value
          Hippo::Image.new(
            select_value(node, 'title/text()'),
            select_value(node, 'description/text()'),
            select_value(node, %w{url/text() @rdf:resource @href text()}),
            select_value(node, 'link/text()'),
            select_value(node, 'height/text()').to_i,
            select_value(node, 'width/text()').to_i,
            select_value(node, %w{style/text() @style})
          )
      end.concat(
        links.select { |link| link.type =~ /^image/ && link.href }.map do |link|
          Hippo::Image.new(link.title, nil, link.href)
        end
      )
    end
    memoize_writer :images
    
    def categories
      try_xpaths_all(channel_node, %w{category dc:subject}).map do |node|
        Hippo::Category.new(
          select_value(node, %w{term text()}),
          select_value(node, %w{@scheme @domain}),
          select_value(node, '@label')
        )
      end
    end
    memoize_writer :categories
    
    def license
      licenses.first
    end
    memoize_writer :license
    
    def licenses
      links.select { |link| link.rel == 'license' }
    end
    memoize_writer :licenses
    
    def icon
      icon_node = try_xpaths(channel_node, %w{link[@rel='icon'] 
        link[@rel='shortcut icon'] link[@type='image/x-icon'] icon 
        logo[@style='icon'] LOGO[@STYLE='ICON']})
      # TODO: resolve relative URIs
      content = select_value(icon_node, %w{@atom10:href @atom03:href 
        @atom:href @href text()}) if icon_node
    end
    memoize_writer :icon
    
    def text_input
      if node = try_xpaths(channel_node, 'textInput')
        returning Hippo::TextInput.new do |input|
          input.title = select_value(node, 'title/text()')
          input.description = select_value(node, 'description/text()')
          input.link = select_value(node, 'link/text()')
          input.name = select_value(node, 'name/text()')
        end
      end
    end
    memoize_writer :text_input

    def generator
      value = select_value(channel_node, 'generator/text()')
      html_to_text(value) if value
    end
    memoize_writer :generator
    
    def docs
      value = select_value(channel_node, 'docs/text()')
      resolve_and_normalize_url(value) if value
    end
    memoize_writer :docs
    
    def favicon
      if link || href
        uri = URI.parse(normalize_url(link || href))
        "http://#{uri.host}/favicon.ico" if uri.scheme == 'http'
      end
    end
    memoize_writer :favicon
    
    def author
      author_node = try_xpaths(channel_node, %w{atom10:author atom03:author 
        atom:author author managingEditor dc:author dc:creator})
      if author_node
        returning Hippo::Author.new do |a|
          a.parse!(author_node)
          a.name = nil if select_value(author_node, "@gr:unknown-author") == "true" && 
            a.name == "(author unknown)"
          a.name ||= itunes_author
        end
      end
    end
    memoize :author
    
    def author=(new_author)
      if new_author.respond_to?(:name) &&
          new_author.respond_to?(:email) &&
          new_author.respond_to?(:url)
        @author = new_author
      else
        @author ||= Hippo::Author.new
        @author.name = new_author
      end
    end
    
    def publisher
      publisher_node = try_xpaths(channel_node, %w{webMaster dc:publisher})
      if publisher_node
        returning Hippo::Author.new do |p|
          p.parse!(publisher_node)
        end
      end
    end
    memoize :publisher
    
    def publisher=(new_publisher)
      if new_publisher.respond_to?(:name) &&
          new_publisher.respond_to?(:email) &&
          new_publisher.respond_to?(:url)
        @publisher = new_publisher
      else
        @publisher ||= Hippo::Author.new
        @publisher.name = new_publisher
      end
    end

    def vidlog
      items.all? do |item|
        item.enclosures.all?(&:video?)
      end
    end
    memoize :vidlog
    alias_method :vidlog?, :vidlog
    
    def podcast
      items.all? do |item|
        item.enclosures.all?(&:audio?)
      end
    end
    memoize :podcast
    alias_method :podcast?, :podcast
    
    def link
      resolve_and_normalize_url(
        if !links.empty?
          links.max {|l| l.rank(self) }.href
        else
          select_value(channel_node, %w{@href @rdf:about @about}) || 
          (is_uri?(guid) && guid =~ /^http:\/\// ? guid : nil)
        end
      )
    end
    cache :link
    
    def links
      try_xpaths_all(channel_node, %w{atom10:link atom03:link atom:link link
        channelLink a url href}).map do |link_node|
          returning Hippo::Link.new do |l|
            l.parse!(link_node, self)
          end
      end
    end
    memoize_writer :links
    
    def href=(value)
      @href = normalize_url(value)
    end
    
    def href
      
    end
    cache :href
    
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
    
    private
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
    
  end
end