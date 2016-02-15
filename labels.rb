require 'csv'
require_relative 'setup.rb'

class LabelGenerator
  attr_reader :filename, :per_inventory

  HEADERS = %w(product_title ventor variant_title price)

  def initialize(filename, per_inventory: false)
    @filename = filename
    @per_inventory = per_inventory
  end

  def generate
    CSV.open(filename, "wb") do |csv|
      csv << ['product_title', 'vendor', 'variant_title', 'price']
      products.each do |product|
        write_product(csv, product)
      end
    end
  end

  private

  def products
    fetch_all_products
  end

  def product_title(product)
    if product.title.start_with?(product.vendor)
      product.title.sub(product.vendor, "").strip
    else
      product.title.strip
    end
  end

  def variant_title(variant)
    if variant.title == "Default Title"
      ""
    else
      variant.title
    end
  end

  def csv_row(product, variant)
    [product_title(product), product.vendor, variant_title(variant), variant.price]
  end

  def variant_count(product, variant)
    case product.product_type
    when "Grocery"
      1
    when "Gift Card", "Workshop", "In Store Beverage"
      0
    else
      if per_inventory
        variant.inventory_quantity
      else
        1
      end
    end
  end

  def write_variant(csv, product, variant)
    variant_count(product, variant).times do
      csv << csv_row(product, variant)
    end
  end

  def write_product(csv, product)
    product.variants.each do |variant|
      write_variant(csv, product, variant)
    end
  end
end

generator = LabelGenerator.new("products.csv", per_inventory: false)
generator.generate
