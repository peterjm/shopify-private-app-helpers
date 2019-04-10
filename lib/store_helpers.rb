require 'dotenv'
require 'pp'
require 'shopify_api'

Dotenv.load

ShopifyAPI::Base.site = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_DOMAIN']}/admin"
ShopifyAPI::Base.api_version = ShopifyAPI::ApiVersion.latest_stable_version

module StoreHelpers
  require_relative 'store_helpers/resources.rb'
  require_relative 'store_helpers/client.rb'
end
