require File.dirname(__FILE__) + "/../test_helper"

class InterfaceTest < Test::Unit::TestCase
  def test_feed_interface
    feed = FeedTools::Feed.new
    assert_respond_to feed, :title
    assert_respond_to feed, :subtitle
    assert_respond_to feed, :description
    assert_respond_to feed, :link
    assert_respond_to feed, :entries
    assert_respond_to feed, :items
  end
  
  def test_feed_item_interface
    feed_item = FeedTools::FeedItem.new
    assert_respond_to feed_item, :title
    assert_respond_to feed_item, :content
    assert_respond_to feed_item, :description
    assert_respond_to feed_item, :link
  end
end