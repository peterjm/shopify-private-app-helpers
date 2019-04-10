module StoreHelpers
  module Resources
    class Base < SimpleDelegator
      attr_reader :client

      class << self
        def to_simple_id(graphql_id)
          graphql_id =~ /(\d+)\z/
          $1.to_i
        end
      end

      def initialize(graphql_object, client)
        super(graphql_object)
        @client = client
      end

      def load_nested_resources
        @loaded_nested_resources = true
      end

      def simple_id
        self.class.to_simple_id(id)
      end

      protected

      def loaded_nested_resources?
        @loaded_nested_resources
      end
    end
  end
end
