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

module FeedTools
  NAMESPACES = {
    "access" => "http://www.bloglines.com/about/specs/fac-1.0",
    "admin" => "http://webns.net/mvcb/",
    "ag" => "http://purl.org/rss/1.0/modules/aggregation/",
    "annotate" => "http://purl.org/rss/1.0/modules/annotate/",
    "atom10" => "http://www.w3.org/2005/Atom",
    "atom03" => "http://purl.org/atom/ns#",
    "atom-blog" => "http://purl.org/atom-blog/ns#",
    "audio" => "http://media.tangent.org/rss/1.0/",
    "bitTorrent" =>"http://www.reallysimplesyndication.com/bitTorrentRssModule",
    "blogChannel" => "http://backend.userland.com/blogChannelModule",
    "blogger" => "http://www.blogger.com/atom/ns#",
    "cc" => "http://web.resource.org/cc/",
    "creativeCommons" => "http://backend.userland.com/creativeCommonsRssModule",
    "co" => "http://purl.org/rss/1.0/modules/company",
    "content" => "http://purl.org/rss/1.0/modules/content/",
    "cp" => "http://my.theinfo.org/changed/1.0/rss/",
    "dc" => "http://purl.org/dc/elements/1.1/",
    "dcterms" => "http://purl.org/dc/terms/",
    "email" => "http://purl.org/rss/1.0/modules/email/",
    "ev" => "http://purl.org/rss/1.0/modules/event/",
    "icbm" => "http://postneo.com/icbm/",
    "image" => "http://purl.org/rss/1.0/modules/image/",
    "indexing" => "urn:atom-extension:indexing",
    "feedburner" => "http://rssnamespace.org/feedburner/ext/1.0",
    "foaf" => "http://xmlns.com/foaf/0.1/",
    "foo" => "http://hsivonen.iki.fi/FooML",
    "fm" => "http://freshmeat.net/rss/fm/",
    "gd" => "http://schemas.google.com/g/2005",
    "gr" => "http://www.google.com/schemas/reader/atom/",
    "itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
    "l" => "http://purl.org/rss/1.0/modules/link/",
    "media" => "http://search.yahoo.com/mrss",
    "p" => "http://purl.org/net/rss1.1/payload#",
    "pingback" => "http://madskills.com/public/xml/rss/module/pingback/",
    "prism" => "http://prismstandard.org/namespaces/1.2/basic/",
    "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
    "ref" => "http://purl.org/rss/1.0/modules/reference/",
    "reqv" => "http://purl.org/rss/1.0/modules/richequiv/",
    "rss09" => "http://my.netscape.com/rdf/simple/0.9/",
    "rss10" => "http://purl.org/rss/1.0/",
    "rss11" => "http://purl.org/net/rss1.1#",
    "rss20" => "http://backend.userland.com/rss2",
    "search" => "http://purl.org/rss/1.0/modules/search/",
    "slash" => "http://purl.org/rss/1.0/modules/slash/",
    "soap" => "http://schemas.xmlsoap.org/soap/envelope/",
    "ss" => "http://purl.org/rss/1.0/modules/servicestatus/",
    "str" => "http://hacks.benhammersley.com/rss/streaming/",
    "sub" => "http://purl.org/rss/1.0/modules/subscription/",
    "syn" => "http://purl.org/rss/1.0/modules/syndication/",
    "taxo" => "http://purl.org/rss/1.0/modules/taxonomy/",
    "thr" => "http://purl.org/rss/1.0/modules/threading/",
    "ti" => "http://purl.org/rss/1.0/modules/textinput/",
    "trackback" => "http://madskills.com/public/xml/rss/module/trackback/",
    "wfw" => "http://wellformedweb.org/CommentAPI/",
    "wiki" => "http://purl.org/rss/1.0/modules/wiki/",
    "xhtml" => "http://www.w3.org/1999/xhtml",
    "xml" => "http://www.w3.org/XML/1998/namespace"
  }
  
  DEFAULTS = {
    :feed_cache => "DatabaseFeedCache",
    :always_strip_wrapper_elements => false,
    :disable_update_from_remote => false,
    :max_ttl => (3 * 24 * 60 * 60 * 60), # 3 days
    :default_ttl => (1 * 60 * 60) # 1 hour
  }
  
  PROCESSORS = %w{libxml} # TODO: hpricot rexml
  ENVIRONMENT = ENV['FEED_TOOLS_ENV'] || ENV['RAILS_ENV'] || 'development'
  
  class << self
    attr_accessor :processor, :feed_cache
    
    def feed_cache
      @feed_cache ||= begin
        cache =  FeedTools.const_get(defaults[:feed_cache])
        cache.initialize_cache
        cache
      rescue NameError
        nil
      end
    end
    
    def defaults
      @defaults ||= ::FeedTools::DEFAULTS.dup
    end

    def load_processor(name)
      require "#{module_dir}/processors/#{name}"
      self.processor = ::FeedTools::Processors.const_get(name.capitalize)
    end
  end
end

$:.unshift File.dirname(__FILE__)
module_dir = File.basename(__FILE__).split('.').first

begin
  require 'rubygems'

  require 'uri'
  require 'time'
  require 'date'
  require 'cgi'
  require 'yaml'
  
  require 'activesupport'

  # Now try to load an XML backend
  procs = FeedTools::PROCESSORS.dup
  begin
    FeedTools.load_processor(procs.shift)
  rescue LoadError, NameError
    retry unless procs.empty?
    raise LoadError.new("No FeedTools XML processors available. Tried #{FeedTools::PROCESSORS.join(', ')}.")
  end
  
  # Mixins
  require "#{module_dir}/memoize"
  require "#{module_dir}/caching"
  require "#{module_dir}/processing"
  require "#{module_dir}/sanitize"
  
  # Core classes
  require "#{module_dir}/feed"
  require "#{module_dir}/feed_item"
  require "#{module_dir}/feed_structures"
  require "#{module_dir}/database_feed_cache"

rescue LoadError => e
  warn "Unexpected LoadError.  It is likely that you are missing a required library: #{e.message}"
end