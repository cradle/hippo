#--
# Copyright (c) 2008 Sean Cribbs
# Copyright (c) 2005 Robert Aman
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

module FeedTools
  # Represents a feed/feed item's category
  Category = Struct.new(:term, :scheme, :label) do
    alias_method :value, :term
    alias_method :category, :term
    alias_method :domain, :scheme
  end

  # Represents a feed/feed item's author
  class Author
    attr_accessor :name, :email, :href, :raw
    include FeedTools::Processing
    include FeedTools::Sanitize

    alias_method :url, :href
    alias_method :url=, :href=
    alias_method :uri, :href
    alias_method :uri=, :href=

    def initialize(*args)
      self.name = args.shift
      self.email = args.shift
      self.href = args.shift
      self.raw = args.shift
    end

    def parse!(node)
      # First try to parse from the raw text of the node
      self.raw = unescape(select_value(node, 'text()'))
      raw_parse!

      # Select some child nodes if the raw didn't work
      self.name ||= unescape(select_value(node, %w{atom10:name/text()
        atom03:name/text() atom:name/text() name/text() @name}))
      self.email ||= unescape(select_value(node, %w{atom10:email/text()
          atom03:email/text() atom:email/text() email/text() @email}))
      self.url ||= unescape(select_value(node, %w{atom10:url/text()
          atom03:url/text() atom:url/text() url/text() atom10:uri/text()
          atom03:uri/text() atom:uri/text() uri/text() @href @uri}))

      # Try to parse out a name if there's some raw content and an email address
      name_parse! if raw && email && !name

      # Normalize the URL
      self.url = resolve_and_normalize_url(self.url, node) if self.url

      self
    end

    private

    def raw_parse!
      # TODO: Simplify, DRY up
      if self.raw
        raw_scan = raw.scan(
          /(.*)\((\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b)\)/i)
        if raw_scan.nil? || raw_scan.size == 0
          raw_scan = raw.scan(
            /(\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b)\s*\((.*)\)/i)
          unless raw_scan.size == 0
            author_raw_pair = raw_scan.first.reverse
          end
        else
          author_raw_pair = raw_scan.first
        end
        if raw_scan.nil? || raw_scan.size == 0
          email_scan = .raw.scan(
            /\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b/i)
          if email_scan != nil && email_scan.size > 0
            self.email = email_scan.first.strip
          end
        end
        unless author_raw_pair.nil? || author_raw_pair.size == 0
          self.name = author_raw_pair.first.strip
          self.email = author_raw_pair.last.strip
        else
          unless raw.include?("@")
            # We can be reasonably sure we are looking at something
            # that the creator didn't intend to contain an email address
            # if it got through the preceeding regexes and it doesn't
            # contain the tell-tale '@' symbol.
            self.name = raw
          end
        end
      end
    end

    def name_parse!
      # TODO: Simplify, DRY up
      name_scan = raw.scan(
        /"?([^"]*)"? ?[\(<].*#{@author.email}.*[\)>].*/)
      if name_scan.flatten.size == 1
        self.name = name_scan.flatten[0].strip
      end
      unless self.name
        name_scan = raw.scan(
          /.*#{@author.email} ?[\(<]"?([^"]*)"?[\)>].*/)
        if name_scan.flatten.size == 1
          self.name = name_scan.flatten[0].strip
        end
      end
    end

  end

  # Represents a feed's image
  Image = Struct.new(:title, :description, :href, :link, :width, :height, :style) do
    alias_method :url, :href
    alias_method :url=, :href=
  end

  # Represents a feed's text input element.
  # Be aware that this will be ignored for feed generation.  It's a
  # pointless element that aggregators usually ignore and it doesn't have an
  # equivalent in all feeds types.
  TextInput = Struct.new(:title, :description, :link, :name)

  # Represents a feed's cloud.
  # Be aware that this will be ignored for feed generation.
  Cloud = Struct.new(:domain, :path, :port, :protocol, :register_procedure)

  # Represents a simple hyperlink
  class Link
    include FeedTools::Processing
    include FeedTools::Sanitize

    attr_accessor :href, :hreflang, :rel, :type, :title, :length
    alias_method :url, :href
    alias_method :url=, :href=

    def initialize(*args)
      [:href, :hreflang, :rel, :type, :title, :length].each do |a|
        send("#{a}=", args.shift)
      end
    end

    def parse!(node, feed)
      # Parse the HREF
      self.href = condense(node, '@href',%w{@atom10:href @atom03:href 
          @atom:href @href text()}))
      # TODO: Figure out this base_uri junk
      # self.href = '' if !href && node.base_uri
      self.href = resolve_and_normalize_url(href)
      href.strip! if href

      # Parse the HREFLANG
      self.hreflang = condense(node, '@hreflang', %w{@atom10:hreflang 
          @atom03:hreflang @atom:hreflang @hreflang})
      hreflang.downcase! if hreflang

      # Parse the REL
      self.rel = condense(node, '@rel', %w{@atom10:rel @atom03:rel @atom:rel @rel})
      rel.downcase! if rel
      self.rel ||= 'alternate' if feed.feed_type == 'atom'

      # Parse the TYPE
      self.type = condense(node, '@type', %w{@atom10:type @atom03:type 
          @atom:type @type})
      type.downcase! if type
      
      # Parse the TITLE
      self.title = condense(node, '@title', %w{@atom10:title @atom03:title
          @atom:title @title text()})
      self.title == nil if title == href
      
      # Parse the LENGTH
      self.length = condense(node, '@length', %w{@atom10:length @atom03:length
         @atom:length @length})
      self.length &&= length.to_i
    end

    def rank(feed)
      return 0 unless href
      score = 0
      score -= 2 if feed.href && feed.href == self.href
      if type
        score -= 2 if type =~ /image|video/
        score += 1 if type =~ /xml$/ || type =~ /xhtml/
        score += (type =~ /html/) ? 2 : -1
      end
      score -= 2 if rel == 'enclosure'
      score += 1 if rel == 'alternate'
      if rel == 'self'
        score -= (href =~ /xml|atom|feed/) ? 2 : 1
      end
    end

    private
    def condense(node, alternate, paths)
      deatomize(node, alternate, select_value(node, paths))
    end
    
    def deatomize(node, attribute, value)
      %w{atom10: atom03: atom:}.include?(value) ? select_value(node, attribute) : value
    end
  end

  # This class stores information about a feed item's file enclosures.
  Enclosure = Struct.new(:href, :type, :file_size, :duration, :height, :width,
    :bitrate, :framerate, :thumbnail, :categories, :hash, :player, :credits, :text,
    :versions, :default_version, :is_default, :explicit, :expression) do
    alias_method :url, :href
    alias_method :url=, :href=
    alias_method :link, :href
    alias_method :link=, :href=
    alias_method :is_default?, :is_default
    alias_method :explicit?, :explicit

    def initialize(*args)
      super
      @expression ||= 'full'
    end

    # Determines if the object is a sample, or the full version of the
    # object, or if it is a stream.
    # Possible values are 'sample', 'full', 'nonstop'.

    EXPRESSIONS = %w{sample full nonstop} #:nodoc:
    # Sets the expression attribute on the enclosure.
    # Allowed values are 'sample', 'full', 'nonstop'.
    def expression=(new_expression)
      if EXPRESSIONS.include?(new_expression.downcase)
        @expression = new_expression.downcase
      end
      @expression
    end

    AUDIO_EXTENSIONS = %w{mp3 m4a m4p wav ogg wma} #:nodoc:
    # Returns true if this enclosure contains audio content
    def audio?
      self.type =~ /^audio/ || AUDIO_EXTENSIONS.any? {|extension| url =~ /#{extension}$/i }
    end

    VIDEO_EXTENSIONS = %w{mov mp4 avi wmv asf} #:nodoc:
    # Returns true if this enclosure contains video content
    def video?
      self.type =~ /^video/ || self.type == 'image/mov' ||
        VIDEO_EXTENSIONS.any? {|extension| url =~ /#{extension}$/i }
    end
  end

  EnclosureHash = Struct.new(:hash, :type)
  EnclosurePlayer = Struct.new(:url, :height, :width)
  EnclosureCredit = Struct.new(:name, :role )
  EnclosureThumbnail = Struct.new(:url, :height, :width)
end