require_relative 'setup.rb'

generator = LabelGenerator.new("products.csv", fetch_all_products, per_inventory: true)
generator.generate
