require 'csv'

module StoreHelpers
  class InventoryReporter
    attr_reader :client, :tax_year, :current_year

    def initialize(client, tax_year=Time.now.year-1)
      @client = client
      @tax_year = tax_year
    end

    def current_year
      tax_year + 1
    end

    def print_inventories
      all_products = client.fetch_products

      groceries = all_products.select { |p| %w(grocery).include?(p.product_type&.downcase) }
      print_inventory_file("inventory_reports/#{tax_year}_grocery_inventory.csv", groceries)

      non_groceries = all_products.select { |p| !%w(grocery workshop).include?(p.product_type&.downcase) }
      print_inventory_file("inventory_reports/#{tax_year}_non_grocery_inventory.csv", non_groceries)
    end

    private

    def quantities_sold_in_current_year_by_variant_id
      @quantities_sold_by_variant_id ||= fetch_quantities_sold_in_year(current_year)
    end

    def orders_since_beginning_of_year(year)
      client.fetch_orders(variables: { query: "created_at:>=#{year}-01-01" })
    end

    def fetch_quantities_sold_in_year(year)
      orders = orders_since_beginning_of_year(year)
      line_items = orders.map(&:line_items).flatten.select(&:simple_variant_id)
      restocked_line_items = orders.map(&:refunds).flatten.map(&:refund_line_items).flatten.select(&:restocked).select(&:simple_variant_id)

      qty = Hash.new(0)

      line_items.each_with_object(qty) do |line_item, qty|
        qty[line_item.simple_variant_id] += line_item.quantity
      end

      restocked_line_items.each_with_object(qty) do |refund_line_item, qty|
        qty[refund_line_item.simple_variant_id] -= refund_line_item.quantity
      end

      qty
    end

    def print_inventory_file(filename, products)
      CSV.open(filename, 'wb') do |csv|
        csv << [
          "Product ID",
          "Variant ID",
          "Product Title",
          "Current Inventory",
          "Sold in #{current_year}",
          "Purchased in #{current_year}",
          "End #{tax_year} Inventory",
          "Retail Price",
          "End #{tax_year} Total Value"
        ]
        products
          .sort_by { |p| p.variants.map(&:inventory_quantity).max }
          .reverse
          .map { |p| p.variants.sort_by(&:inventory_quantity).reverse }
          .flatten
          .each do |v|
          p = v.product
          csv << [
            p.simple_id,
            v.simple_id,
            v.full_title,
            v.inventory_quantity,
            quantities_sold_in_current_year_by_variant_id[v.simple_id],
            0,
            nil,
            v.price,
            nil
          ]
        end
      end
      puts "wrote to #{filename}"
    end
  end
end
