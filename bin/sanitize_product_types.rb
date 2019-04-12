require 'store_helpers/product_type_sanitizer.rb'
require 'store_helpers.rb'

def perform_updates(args)
  "--dry-run=false".in?(args)
end

client = StoreHelpers::Client.new
sanitizer = StoreHelpers::ProductTypeSanitizer.new(client, perform_updates(ARGV))
sanitizer.sanitize
sanitizer.summarize
