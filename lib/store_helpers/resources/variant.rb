module StoreHelpers
  module Resources
    class Variant < Base
      attr_reader :product

      def initialize(graphql_variant, client, product)
        super(graphql_variant, client)
        @product = product
      end

      def full_title
        parts = [product.title]
        parts << title unless default?
        parts.join(" - ")
      end

      def default?
        product.has_only_default_variant
      end

      def inspect
        barcode = " - #{barcode}" if barcode.present?
        puts "[#{product.simple_id}] #{full_title} ($#{price})#{barcode}"
      end
    end
  end
end
