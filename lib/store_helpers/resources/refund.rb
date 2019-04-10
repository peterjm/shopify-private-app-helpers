module StoreHelpers
  module Resources
    class Refund < Base
      attr_reader :order

      def initialize(graphql_refund, client, order)
        super(graphql_refund, client)
        @order = order
      end

      def refund_line_items
        raise "need to setup refund line items" unless loaded_nested_resources?
        @refund_line_items
      end

      def load_nested_resources
        load_refund_line_items
        super
      end

      private

      def load_refund_line_items
        raw_refund_line_items = __getobj__.refund_line_items.edges.map(&:node)
        @refund_line_items = raw_refund_line_items.map { |li| RefundLineItem.new(li, client, self) }
        @refund_line_items.each(&:load_nested_resources)
      end
    end
  end
end
