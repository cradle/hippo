module FeedTools
  module Sanitize
    # Unescapes HTML entities and removes script tags, stripping whitespace 
    # from the result
    def unescape_and_sanitize(text)
      sanitize(unescape(text)).strip
    end

    # Escapes control characters into their corresponding HTML entities
    def escape(text)
      CGI.escapeHTML(text).gsub(/'/, '&apos;').gsub(/"/, '&quot;')
    end

    # Unescapes HTML/XML entities into their original characters
    def unescape(text)
      CGI.unescapeHTML(
        text.gsub(/&#x26;/, "&amp;").
          gsub(/&#38;/, "&amp;").
          gsub(/&#0*((?:\d+)|(?:x[a-f0-9]+));/) do |s|
            m = $1
            m = "0#{m}" if m[0] == ?x
            [Integer(m)].pack('U*')
          end
      ).gsub(/&apos;/, "'").gsub(/&quot;/, '"')
    end

    # Sanitizes script tags out of the passed text or HTML
    def sanitize(text)
      # TODO: sanitize_html missing from original HtmlHelper
      # Let's just assume we're stripping scripts and styles
      text.gsub(/<script[^>]*>(.|\n)*(<\/script>)?/i, '').
        gsub(/<style[^>]*>(.|\n)*(<\/style>)?/i, '')
    end
    
    # Strips HTML tags from the input
    def strip_html(html)
      html.gsub(/<\/?[^>]+>/, '')
    end

    # Converts HTML into plain text, stripping tags and unescaping entitites
    def html_to_text(html)
      unescape(strip_html(html)).
        gsub(/&#8216;/, "'").
        gsub(/&#8217;/, "'").
        gsub(/&#8220;/, "\"").
        gsub(/&#8221;/, "\"")
    end
  end
end