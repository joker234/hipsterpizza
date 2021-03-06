# encoding: utf-8

# monkey patching Billy to suit our special need to cache everything
# excluding pages with the /hipster prefix. This means that all requests
# to pizza.de (and other domains) are cached after being processed by
# lib/forwarder.rb and the passthrough_controller.
module Billy
  class ProxyConnection < EventMachine::Connection
    def cacheable?(headers, status)
      return false unless Billy.config.cache

      url = URI(@url)
      return false if url.path.start_with?('/hipster') || url.path == '/'
      # new and edit order share the same URL and are discerned by
      # cookies only. Caching would thus incorrectly handle replay data.
      return false if url.query.include?('knddomain=1') rescue false

      # This is used to assert proper replacement in passthrough_spec.
      # The problem is that Billy will cache the redirect to the new URL
      # – which includes the random port, thus making the test fail once
      # the cache is primed. TODO: Discard cache if there’s a redirect
      # to localhost instead of hardcoding this value.
      return false if url.path == '/0_image/pizza-de_logoshop_v8.gif'

      true
    end
  end
end

Billy.configure do |c|
  c.cache = true
  c.ignore_params = [
    'http://stats.g.doubleclick.net/__utm.gif',
    'http://logc279.xiti.com/hit.xiti',
    'https://apis.google.com/_/+1/fastbutton',
    'https://accounts.google.com/o/oauth2/postmessageRelay',
    # the same store is used for all tests, so the params do not matter
    # for this
    'http://localhost/_shop/shopinit_json',
    'http://127.0.0.1/_shop/shopinit_json'
  ]
  c.persist_cache = true
  c.cache_path = 'tmp/billy-reqs/'
end

# ensure Billy’s cache directory exists
Dir.chdir(File.join(File.dirname(__FILE__), '..', '..')) do
  FileUtils.mkdir_p(Billy.config.cache_path)
end
