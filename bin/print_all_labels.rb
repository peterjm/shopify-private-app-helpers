require 'store_helpers/label_generator.rb'
require 'store_helpers.rb'

client = StoreHelpers::Client.new
generator = LabelGenerator.new("products.csv", client.fetch_products, per_inventory: true)
generator.generate
