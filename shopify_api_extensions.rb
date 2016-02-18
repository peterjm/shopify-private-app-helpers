class ShopifyAPI::Product
  def has_options?
    !(variants.length == 1 && variants.first.default?)
  end
end

class ShopifyAPI::Variant
  DEFAULT_TITLE = "Default Title"

  attr_accessor :product

  def default?
    title == DEFAULT_TITLE
  end
end
