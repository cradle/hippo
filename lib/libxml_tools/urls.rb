module FeedTools
  module URLs
    # Encapsulate the file:// resolution and URI normalization
    def resolve_and_normalize_url(url)
      normalize_url(resolve_url(url))
    end
    
    # Normalize a URL
    def normalize_url(url)
      # TODO
      url
    end
    
    def resolve_url(url)
      url
    end
    
    def is_uri?(url)
      begin
        uri = URI.parse(url)
        uri && uri.scheme
      rescue URI::InvalidURIError
        false
      end
    end
  end
end