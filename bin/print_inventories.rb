require 'store_helpers/inventory_reporter.rb'
require 'store_helpers.rb'

def fetch_year(args)
  args.detect { |arg| arg =~ /\A--year=(\d{4})\z/ }
  if $1
    $1.to_i
  else
    puts "Please specify a year, e.g."
    puts "ruby #{__FILE__} --year=1981"
    nil
  end
end

year = fetch_year(ARGV) or return(1)
client = StoreHelpers::Client.new
reporter = StoreHelpers::InventoryReporter.new(client, year)
reporter.print_inventories
