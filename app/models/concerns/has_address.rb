module HasAddress
  extend ActiveSupport::Concern

  def format_address
    [ street_address, city, state, zip ].filter_map(&:presence).join(", ")
  end

  def short_address
    [ street_address, city, state ].filter_map(&:presence).join(", ")
  end
end
