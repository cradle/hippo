module FeedTools
  class FeedItem
    # To be replaced later
    attr_accessor :title, :content, :summary, :link, :id
    attr_reader :feed
    
    alias_method :abstract, :summary
    alias_method :abstract=, :summary=
    alias_method :description, :summary
    alias_method :description=, :summary=
    alias_method :copyright, :rights
    alias_method :copyright=, :rights=
    alias_method :guid, :id
    alias_method :guid=, :id=
  end
end