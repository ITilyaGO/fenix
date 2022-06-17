class OrderAssist
  extend Fenix::App::OrdersHelper
  extend Fenix::App::ProductsHelper
  extend Fenix::App::KyotoHelpers

  def self.calc_complexity_for(order)
    cplx = order_complexity order
    CabiePio.set [:complexity, :order], order.id, cplx
    @complex_hash = nil
  end

  def self.calc_stickers_for(order)
    price = sticker_price order
    CabiePio.set [:sticker, :order], order.id, price.first
    CabiePio.set [:sticker, :order_glass], order.id, price.last
  end
end