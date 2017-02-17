require 'csv'
require_relative 'setup.rb'

DATE_2017 = Time.parse("2017-01-01")

def quantity_by_variant_id
  @quantity_by_variant_id ||= begin
    orders = orders_since(DATE_2017)
    refunds = orders.map(&:refunds).flatten

    qty = Hash.new(0)

    orders.map(&:line_items).flatten.each_with_object(qty) do |line_item, qty|
      qty[line_item.variant_id] += line_item.quantity
    end

    refunds.select(&:restock).map(&:refund_line_items).flatten.each_with_object(qty) do |refund_line_item, qty|
      qty[refund_line_item.line_item.variant_id] -= refund_line_item.quantity
    end

    qty
  end
end

def quantity_sold_in_2017(variant)
  quantity_by_variant_id[variant.id]
end

def print_inventory_file(filename, products)
  CSV.open(filename, 'wb') do |csv|
    csv << [
      "Product ID",
      "Variant ID",
      "Product Title",
      "Current Inventory",
      "Sold in 2017",
      "Purchased in 2017",
      "End 2016 Inventory",
      "Retail Price",
      "End 2016 Total Value"
    ]
    products
      .sort_by { |p| p.variants.map(&:inventory_quantity).max }
      .reverse
      .map { |p| p.variants.sort_by(&:inventory_quantity).reverse }
      .flatten
      .each do |v|
      p = v.product
      csv << [
        p.id,
        v.id,
        variant_title(v),
        v.inventory_quantity,
        quantity_sold_in_2017(v),
        0,
        nil,
        v.price,
        nil
      ]
    end
  end
end

def print_inventories()
  all_products = fetch_all_products

  groceries = all_products.select { |p| %w(grocery).include?(p.product_type&.downcase) }
  print_inventory_file("grocery_inventory.csv", groceries)

  non_groceries = all_products.select { |p| !%w(grocery workshop).include?(p.product_type&.downcase) }
  print_inventory_file("non_grocery_inventory.csv", non_groceries)
end

if __FILE__ == $0
  print_inventories()
end
