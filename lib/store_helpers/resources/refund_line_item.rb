module StoreHelpers
  module Resources
    class RefundLineItem < Base
      attr_reader :refund

      def initialize(graphql_refund_line_item, client, refund)
        super(graphql_refund_line_item, refund)
        @refund = refund
      end

      def simple_variant_id
        Base.to_simple_id(line_item.variant.id) if line_item.variant
      end
    end
  end
end
