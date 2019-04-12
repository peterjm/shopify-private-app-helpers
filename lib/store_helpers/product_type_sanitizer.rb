module StoreHelpers
  class ProductTypeSanitizer
    STOP_WORDS = %w(And Or)

    TYPES_TO_RENAME = {
      'Good Name' => ['Bad Name'],
    }.each_with_object({}) { |(good_name, bad_names), renames| bad_names.each { |name| renames[name] = good_name } }

    attr_reader :client, :perform_updates

    def initialize(client, perform_updates=false)
      @client = client
      @perform_updates = perform_updates
    end

    def sanitize
      ensure_consistent_casing(all_products)
      rename_duplicates(all_products)
    end

    def summarize
      counts_by_type = all_products.each_with_object({}) do |product, acc|
        acc[product.product_type] ||= 0
        acc[product.product_type] += 1
      end
      counts_and_types = counts_by_type.sort
      counts_and_types.each do |type, count|
        puts "#{type} - #{count}"
      end
    end

    private

    def rename_duplicates(products)
      products.each do |product|
        renamed_type = TYPES_TO_RENAME[product.product_type]
        update_product_type(product, renamed_type) if renamed_type
      end
    end

    def ensure_consistent_casing(products)
      products.each do |product|
        consistent_cased_type = consistent_case(product.product_type)
        update_product_type(product, consistent_cased_type)
      end
    end

    def update_product_type(product, new_type)
      original_type = product.product_type
      if original_type != new_type
        if perform_updates
          client.update_product(
            product,
            fields: { product_type: new_type },
            mutation: Client::UPDATE_PRODUCT_TYPE_MUTATION
          )
        end
        puts "change '#{original_type}' to '#{new_type}' on #{product.title}"
      end
    end

    def consistent_case(type)
      new_type = type.titleize
      words = new_type.split
      words = words.map { |word| word.in?(STOP_WORDS) ? word.downcase : word }
      words.join(" ")
    end

    def all_products
      @all_products ||= client.fetch_products(query: Client::BASIC_PRODUCTS_QUERY)
    end
  end
end
