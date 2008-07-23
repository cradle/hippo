module FeedTools
  module Sanitize
    def unescape_and_sanitize(text)
      sanitize(unescape(text)).strip
    end

    def escape(text)
      CGI.escapeHTML(text).gsub(/'/, '&apos;').gsub(/"/, '&quot;')
    end

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

    # TODO: sanitize_html missing from original HtmlHelper
    def sanitize(text)
      text
    end
  end
end