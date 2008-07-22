require File.dirname(__FILE__) + "/../test_helper"

class RdfTest < Test::Unit::TestCase
  
  def test_embedded_atom_self_link
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="UTF-8"?>
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns="http://purl.org/rss/1.0/">
        <channel rdf:about="http://example.com/">
          <atom10:link xmlns:atom10="http://www.w3.org/2005/Atom"
            rel="self" type="application/rss+xml"
            href="http://example.com/feed.rdf" />
        </channel>
      </rdf:RDF>
    FEED
    ) { |feed|
      assert_equal("http://example.com/", feed.link)
      assert_equal("http://example.com/feed.rdf", feed.href)
      assert_equal("http://example.com/feed.rdf", feed.base_uri)
    }
  end

  def test_relative_uri_resolution
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="UTF-8"?>
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns="http://purl.org/rss/1.0/">
        <channel rdf:about="http://example.com/">
          <items>
            <rdf:Seq>
              <rdf:li rdf:resource="http://example.com/entry/" />
            </rdf:Seq>
          </items>
          <atom10:link xmlns:atom10="http://www.w3.org/2005/Atom"
            rel="self" type="application/rss+xml"
            href="http://example.com/feed.rdf" />
        </channel>
        <item rdf:about="http://example.com/entry/">
          <link>http://example.com/entry/</link>
          <description>
            A relative &lt;a href="/relative/location/"&gt;uri&lt;/a&gt;.
          </description>
        </item>
      </rdf:RDF>
    FEED
    ) { |feed|
      assert_equal("http://example.com/", feed.link)
      assert_equal("http://example.com/feed.rdf", feed.href)
      assert_equal("http://example.com/feed.rdf", feed.base_uri)
      assert_equal(1, feed.items.size)
      assert_equal("http://example.com/entry/", feed.items[0].link)
      assert_equal(1, feed.items[0].description.scan(
        "http://example.com/relative/location/").size)
    }
  end
end
