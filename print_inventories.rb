require 'csv'
require_relative 'setup.rb'

def beginning_of_year(year)
  Time.parse("#{year}-01-01")
end

def fetch_quantities_sold_in_year(year)
  orders = orders_since(beginning_of_year(year))
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

def print_inventory_file(filename, fiscal_year, products, quantities_sold_by_variant_id)
  current_year = fiscal_year + 1
  CSV.open(filename, 'wb') do |csv|
    csv << [
      "Product ID",
      "Variant ID",
      "Product Title",
      "Current Inventory",
      "Sold in #{current_year}",
      "Purchased in #{current_year}",
      "End #{fiscal_year} Inventory",
      "Retail Price",
      "End #{fiscal_year} Total Value"
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
        quantities_sold_by_variant_id[v],
        0,
        nil,
        v.price,
        nil
      ]
    end
  end
end

def print_inventories(year)
  all_products = fetch_all_products
  quantities_sold_by_variant_id = fetch_quantities_sold_in_year(year+1)

  groceries = all_products.select { |p| %w(grocery).include?(p.product_type&.downcase) }
  print_inventory_file("grocery_inventory.csv", year, groceries, quantities_sold_by_variant_id)

  non_groceries = all_products.select { |p| !%w(grocery workshop).include?(p.product_type&.downcase) }
  print_inventory_file("non_grocery_inventory.csv", year, non_groceries, quantities_sold_by_variant_id)
end

if __FILE__ == $0
  print_inventories(2017)
end
