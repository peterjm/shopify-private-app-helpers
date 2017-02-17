require 'dotenv'
require 'pp'
require 'shopify_api'

require_relative 'shopify_api_extensions.rb'
require_relative 'label_generator.rb'

Dotenv.load

ShopifyAPI::Base.site = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_DOMAIN']}/admin"

API_CALL_LIMIT = 40
API_CALLS_PER_SECOND = 2
DEFAULT_VARIANT_TITLE = "Default Title"

def reload_setup
  load "setup.rb"
end

def fetch_all_products
  products = fetch_all(ShopifyAPI::Product)
  products.each{ |p| set_product_on_variants(p) }
  products
end

def fetch_all_orders
  fetch_all(ShopifyAPI::Order, status: "any")
end

def fetch_all(klass, params={})
  page = 1
  limit = 250
  resources = []
  loop do
    batch = klass.find(:all, params: params.merge(limit: limit, page: page)).to_a
    resources += batch
    break if batch.length < limit
    page += 1
  end
  resources
end

def set_product_on_variants(product)
  product.variants.each{ |v| v.product = product }
end

def products_matching(products=nil, &block)
  products ||= fetch_all_products
  products.select(&block)
end

def variants_matching(products=nil, &block)
  products ||= fetch_all_products
  products.map(&:variants).flatten.select(&block)
end

def print_products(products)
  products.each{ |p| print_product(p) }
  nil
end

def print_product(product)
  puts "[#{product.id}] #{product.title}"
end

def print_variants(variants)
  variants.each{ |v| print_variant(v) }
  nil
end

def variant_title(variant)
  variant_title = variant.title unless variant.title == "Default Title"
  [variant.product.title, variant_title].compact.join(" - ")
end

def print_variant(variant)
  product = variant.product

  barcode = " - #{variant.barcode}" if variant.barcode.present?
  puts "[#{product.id}] #{variant_title(variant)} ($#{variant.price})#{barcode}"
end

def edit_products(products, &block)
  count = 0
  products.each do |p|
    if block.call(p)
      p.save
      sleep(1.to_f / API_CALLS_PER_SECOND) if count > API_CALL_LIMIT - 5
      count += 1
    end
  end
  count
end

def edit_variants(products, &block)
  edit_products(products) { |p| p.variants.map(&block).any? }
end

def orders_matching(orders=nil, &block)
  orders ||= fetch_all_orders
  orders.select(&block)
end

def orders_since(time)
  orders_matching do |o|
    Time.parse(o.created_at) > time
  end
end
