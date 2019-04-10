module StoreHelpers
  module Resources
    class LineItem < Base
      attr_reader :order

      def initialize(graphql_line_item, client, order)
        super(graphql_line_item, client)
        @order = order
      end

      def simple_variant_id
        Base.to_simple_id(variant.id) if variant
      end
    end
  end
end
