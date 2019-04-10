require 'store_helpers/google_chart_javascript.rb'
require 'store_helpers.rb'

client = StoreHelpers::Client.new
orders = client.fetch_all_orders
puts count_chart_js_for_orders(orders)
