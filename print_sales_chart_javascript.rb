require_relative 'setup.rb'
require_relative 'google_chart_javascript.rb'

orders = fetch_all_orders
#orders = ShopifyAPI::Order.find(:all)
puts count_chart_js_for_orders(orders)
