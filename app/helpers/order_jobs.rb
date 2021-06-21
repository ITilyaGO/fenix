class OrderJobs
  extend Fenix::App::OrdersHelper
  extend Fenix::App::ProductsHelper
  extend Fenix::App::KyotoHelpers
  ONLINE_COUNT_FILE = Padrino.env == :production ? '../yardekol/count.txt' : 'count.txt'

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

  def self.stock_job(force: false, all: false)
    # CabiePio.clear(:stock, :product) if force
    # CabiePio.clear(:stock, :common, :a) if force
    CabiePio.clear(:need, :order) if force
    CabiePio.clear(:need, :product) if force
    CabiePio.clear(:need, :archetype) if force
    CabiePio.clear(:stock, :archetype) if force
    # CabiePio.clear(:stock, :order, :done) if force

    orders = Order.where("status = ?", Order.statuses[:current])
    orders.each do |t|
      #bal_need_order_start(t)
    end
  end

  def self.online_count
    @online_date = nil if (Time.now - (@online_date||Time.now)) > 60 && @online_date < File.ctime(ONLINE_COUNT_FILE)
    @online_count = nil unless @online_date
    @online_date ||= File.ctime(ONLINE_COUNT_FILE)
    @online_count ||= File.read(ONLINE_COUNT_FILE).to_i
  end
end