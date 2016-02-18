require_relative 'setup.rb'

products = products_matching{ |p| p.tags.include?("Generated Barcode") }
products_with_options = products.select(&:has_options?)
products_without_options = products - products_with_options

generator = LabelGenerator.new("generated_barcodes_with_options.csv", products_with_options, per_inventory: true)
generator.generate

generator = LabelGenerator.new("generated_barcodes_without_options.csv", products_without_options, per_inventory: true)
generator.generate
