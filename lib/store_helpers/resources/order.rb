module StoreHelpers
  module Resources
    class Order < Base
      def line_items
        raise "need to setup line items" unless loaded_nested_resources?
        @line_items
      end

      def refunds
        raise "need to setup refunds" unless loaded_nested_resources?
        @refunds
      end

      def load_nested_resources
        load_line_items
        load_refunds
        super
      end

      private

      def load_full_order
        @raw_order ||= client.raw_order(id: id)
      end

      def load_line_items
        if __getobj__.respond_to?(:line_items)
          raw_line_items = __getobj__.line_items
          if raw_line_items.page_info.has_next_page
            raw_order = load_full_order
            raise "can't handle number of line items" if raw_order.line_items.page_info.has_next_page
            raw_line_items = raw_order.line_items
          end
          @line_items = raw_line_items.edges.map(&:node).map { |li| LineItem.new(li, client, self) }
        else
          raise "implement querying for line items"
        end
      end

      def load_refunds
        if __getobj__.respond_to?(:refunds)
          raw_refunds = __getobj__.refunds
          if raw_refunds.any? { |r| r.refund_line_items.page_info.has_next_page }
            raw_order = load_full_order
            raise "can't handle number of refund line items" if raw_order.refunds.any? { |r| r.refund_line_items.page_info.has_next_page }
            raw_refunds = raw_order.refunds
          end
          @refunds = raw_refunds.map { |li| Refund.new(li, client, self) }
          @refunds.each(&:load_nested_resources)
        else
          raise "implement querying for refunds"
        end
      end
    end
  end
end
