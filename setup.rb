require 'dotenv'
require 'shopify_api'

require_relative 'shopify_api_extensions.rb'

Dotenv.load

ShopifyAPI::Base.site = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_DOMAIN']}/admin"

def reload_setup
  load "setup.rb"
end

def fetch_all_products
  page = 1
  limit = 250
  products = []
  loop do
    batch = ShopifyAPI::Product.find(:all, params: {limit: limit, page: page}).to_a
    products += batch
    break if batch.length < limit
    page += 1
  end

  products.each{ |p| set_product_on_variants(p) }

  products
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

def print_variant(variant)
  product = variant.product

  title = if variant.title == "Default Title"
    product.title
  else
    "#{product.title} - #{variant.title}"
  end
  barcode = " - #{variant.barcode}" if variant.barcode.present?
  puts "[#{product.id}] #{title} ($#{variant.price})#{barcode}"
end
