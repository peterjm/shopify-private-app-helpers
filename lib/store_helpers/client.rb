module StoreHelpers
  class Client
    GraphQL = ShopifyAPI::GraphQL.new

    class EmptyFirstPage
      class PageInfo
        def has_next_page
          true
        end
      end

      def page_info
        PageInfo.new
      end

      def edges
        []
      end
    end

    attr_reader :client

    BASIC_PRODUCTS_QUERY = GraphQL.parse(File.read('graphql/basic_products_query.graphql'))
    PRODUCTS_QUERY = GraphQL.parse(File.read('graphql/products_query.graphql'))
    PRODUCT_VARIANTS_QUERY = GraphQL.parse(File.read('graphql/product_variants_query.graphql'))
    ORDERS_QUERY = GraphQL.parse(File.read('graphql/orders_query.graphql'))
    ORDER_QUERY = GraphQL.parse(File.read('graphql/order_query.graphql'))

    UPDATE_PRODUCT_TYPE_MUTATION = GraphQL.parse(File.read('graphql/update_product_type_mutation.graphql'))

    def update_product(product, fields:, mutation:)
      response = make_request(
        query: mutation,
        variables: { id: product.id }.merge(fields),
        desc: 'product update',
        estimated_cost: 100,
      )
    end

    def fetch_products(query: PRODUCTS_QUERY)
      raw_products = paginate_products(query: query)
      products = raw_products.map { |p| Resources::Product.new(p, self) }
      products.each(&:load_nested_resources)
      products
    end

    def fetch_orders(query: ORDERS_QUERY, variables: {})
      raw_orders = paginate_orders(query: query, variables: variables)
      orders = raw_orders.map { |o| Resources::Order.new(o, self) }
      orders.each(&:load_nested_resources)
      orders
    end

    def raw_order(id:, query: ORDER_QUERY)
      response = make_request(
        query: query,
        variables: { id: id },
        desc: 'order',
        estimated_cost: 550,
      )
      response.data.order
    end

    def paginate_products(**args)
      paginate(**args.merge(desc: 'products')) do |response|
        response.data.products
      end
    end

    def paginate_variants(**args)
      paginate(**args.merge(desc: 'variants')) do |response|
        response.data.product.variants
      end
    end

    def paginate_orders(**args)
      paginate(**args.merge(desc: 'orders', estimated_cost: 1000)) do |response|
        response.data.orders
      end
    end

    private

    def paginate(query:, variables: {}, desc: 'resources', estimated_cost: 0, page: EmptyFirstPage.new, &block)
      requests = 1
      resources = page.edges.map(&:node)
      while page.page_info.has_next_page
        cursor = page.edges.last&.cursor
        response = make_request(
          query: query,
          variables: variables.merge(first: 50, after: cursor),
          count: requests,
          desc: desc,
          estimated_cost: estimated_cost,
        )
        page = yield(response)
        resources += page.edges.map(&:node)
        requests += 1
        estimated_cost = response.extensions["cost"]["requestedQueryCost"]
      end
      resources
    end

    attr_reader :last_throttle_status, :last_throttle_time

    def store_throttle(response)
      @last_throttle_status = response.extensions["cost"]["throttleStatus"]
      @last_throttle_time = Time.now
    end

    def make_request(query:, variables:, desc:, count: 1, estimated_cost: 0)
      sleep_to_handle_throttle(estimated_cost)
      puts "making request #{count} for #{desc} (#{variables.inspect})"
      response = GraphQL.query(query, variables: variables)
      store_throttle(response)
      unless response.data
        puts response.inspect
        raise "need to handle errors"
      end
      response
    end

    def sleep_to_handle_throttle(requested_cost)
      return unless requested_cost > 0
      return unless last_throttle_status

      currently_available = last_throttle_status["currentlyAvailable"]
      restore_rate = last_throttle_status["restoreRate"]
      elapsed_time = last_throttle_time ? Time.now - last_throttle_time : 0

      seconds_to_recover = (requested_cost - currently_available) / restore_rate
      seconds_to_sleep = seconds_to_recover - elapsed_time
      if seconds_to_sleep > 0
        sleep seconds_to_sleep
      end
    end
  end
end
