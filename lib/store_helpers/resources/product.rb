module StoreHelpers
  module Resources
    class Product < Base
      def variants
        @variants
      end

      def load_nested_resources
        load_variants
        super
      end

      def inspect
        "[#{id}] #{title}"
      end

      private

      def load_variants
        if __getobj__.respond_to?(:variants)
          raw_variants = client.paginate_variants(
            query: Client::PRODUCT_VARIANTS_QUERY,
            variables: { product_id: id },
            page: __getobj__.variants,
          )
          @variants = raw_variants.map { |v| Variant.new(v, client, self) }
        end
      end
    end
  end
end
