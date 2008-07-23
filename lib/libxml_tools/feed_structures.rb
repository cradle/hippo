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
  Author = Struct.new(:name, :email, :href, :raw) do
    alias_method :url, :href
    alias_method :url=, :href=
    alias_method :uri, :href
    alias_method :uri=, :href=
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
  Link = Struct.new(:href, :hreflang, :rel, :type, :title, :length) do
    alias_method :url, :href
    alias_method :url=, :href=
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

  EnclosureHash = Struct.new(:hash, :type )
  EnclosurePlayer = Struct.new(:url, :height, :width )
  EnclosureCredit = Struct.new(:name, :role )
  EnclosureThumbnail = Struct.new(:url, :height, :width )
end