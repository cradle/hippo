require File.dirname(__FILE__) + "/../test_helper"

class InterfaceTest < Test::Unit::TestCase
  def test_feed_interface
    # These will throw an exception if missing, obviously
    feed = FeedTools::Feed.new
    feed.title
    feed.subtitle
    feed.description
    feed.link
    feed.entries
    feed.items
  end
  
  def test_feed_item_interface
    # These will throw an exception if missing, obviously
    feed_item = FeedTools::FeedItem.new
    feed_item.title
    feed_item.content
    feed_item.description
    feed_item.link
  end
end