$: << File.dirname(__FILE__) + "/../lib"

require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class Test::Unit::TestCase
  include FeedTools::FeedToolsHelper
  FeedTools::FeedToolsHelper.default_local_path = File.expand_path(File.dirname(__FILE__) + '/feeds')
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    unless ActiveRecord::Base.connected?
      config = YAML::load_file(File.dirname(__FILE__) + '/database.yml')
      ActiveRecord::Base.establish_connection(config)
    end
  end
end