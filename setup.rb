require 'dotenv'
require 'shopify_api'

session = ShopifyAPI::Session.new(ENV['SHOPIFY_DOMAIN'], ENV['SHOPIFY_TOKEN'])
ShopifyAPI::Base.activate_session(session)
