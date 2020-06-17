class OrderJobs
  extend Fenix::App::OrdersHelper
  extend Fenix::App::ProductsHelper
  extend Fenix::App::KyotoHelpers

  def self.complexity_job(force: false, all: false)
    CabiePio.clear(:complexity, :order) if force
    orders = all ?
      Order.where('updated_at < ?', Date.today - 4.month) :
      Order.where('updated_at > ?', Date.today - 4.month) 
    orders.each do |t|
      calc_complexity_for(t)
    end
    wonderbox_set(:complexity_job, !all)
  end

  def self.sticker_job(force: false, all: false)
    CabiePio.clear(:sticker, :order) if force
    orders = all ?
      Order.where('updated_at < ?', Date.today - 4.month) :
      Order.where('updated_at > ?', Date.today - 4.month) 
    orders.each do |t|
      calc_stickers_for(t)
    end
    wonderbox_set(:sticker_job, !all)
  end
end