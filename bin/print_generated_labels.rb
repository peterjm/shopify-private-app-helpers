require 'store_helpers/label_generator.rb'
require 'store_helpers.rb'

client = StoreHelpers::Client.new
products = client.fetch_products
products = products.select { |p| p.tags.include?("Generated Barcode") }

products_without_options = products.select(&:has_only_default_variant)
products_with_options = products - products_without_options

generator = LabelGenerator.new("generated_barcodes_with_options.csv", products_with_options, per_inventory: true)
generator.generate

generator = LabelGenerator.new("generated_barcodes_without_options.csv", products_without_options, per_inventory: true)
generator.generate
