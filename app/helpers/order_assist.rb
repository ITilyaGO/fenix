class OrderAssist
  extend Fenix::App::OrdersHelper
  extend Fenix::App::ProductsHelper

  def self.calc_complexity_for(order)
    cplx = order_complexity order
    CabiePio.set [:complexity, :order], order.id, cplx
    @complex_hash = nil
  end

  def self.calc_stickers_for(order)
    price = sticker_price order
    CabiePio.set [:sticker, :order], order.id, price
  end
end