module Fenix::App::OrdersHelper
  def s_btns(sections, parts)
    # @page = page
    # @pages = pages
    # @c = c
    # @m = m
    # @r = route
    partial "orders/progress"
  end
  
  # def order_squares(order, sections)
  #   partial "orders/squares", :locals => { :sections => sections, :order => order }
  # end

  def deli(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1 ').reverse
  end

  def to_rub(value)
    ("%.2f" % value).gsub('.', ',')
  end

  def listrur(value)
    # TODO: rebuild font with ruble sign ₽
    "<span class='r'>&#x20B7</span>#{'%0.f' %(value||0)}"
  end

  def rur_sym(value)
    "#{value}&nbsp;<span class='r'>&#x20B7</span>"
  end

  def rur(value)
    # TODO: rebuild font with ruble sign ₽
    "#{'%0.f' %(value||0)}&nbsp;<span class='r'>&#x20B7</span>"
  end

  def rurk(value)
    # TODO: rebuild font with ruble sign ₽
    "#{'%.2f' %(value||0)}&nbsp;<span class='r'>&#x20B7</span>"
  end

  def hide_zero_value_rur(value)
    # TODO: rebuild font with ruble sign ₽
    value ||= 0
    value.to_f > 0 ? rur_sym('%0.f' %(value)) : nil
  end

  def hide_zero_value_rurk(value)
    # TODO: rebuild font with ruble sign ₽
    value ||= 0
    value.to_f > 0 ? rur_sym('%.2f' %(value)) : nil
  end

  def pic_path(img)
    "#{Padrino.root}/public/images/orders/#{img}"
  end

  def order_complexity(order)
    kc_complex = CabiePio.folder(:complexity, :category)
    complexity = 0
    order.order_lines.each do |line|
      next if line.ignored || line.amount == 0
      formula = CabiePio.get [:complexity, :product], line.product_id
      formula = kc_complex.fetch(products_hash[line.product_id].to_s) if formula.blank?
      formula = kc_complex.fetch(category_matrix[products_hash[line.product_id]].to_s) unless formula

      complex = formula.data.split.map{|v|v.split(':').map(&:to_i)} rescue nil
      value = complex.reject{|x|x.first>line.amount}.pop.last rescue 0
      complexity += value
    end
    complexity
  end

  def calc_complexity_for(order)
    cplx = order_complexity order
    CabiePio.set [:complexity, :order], order.id, cplx
    @complex_hash = nil
  end

  def order_cplx(id)
    cabie = CabiePio.get [:complexity, :order], id
    cabie.data
  end

  def complex_hash
    @complex_hash ||= CabiePio.folder(:complexity, :order).flat
  end

  def order_sticker(id)
    cabie = CabiePio.get [:sticker, :order], id
    cabieglass = CabiePio.get [:sticker, :order_glass], id
    [cabie.data.to_f - cabieglass.data.to_f, cabieglass.data.to_f]
  end

  def sticker_price(order)
    kc_sticker = CabiePio.folder(:products, :sticker).flat.trans(nil, :to_f)
    sticker = 0
    glass = 0
    order.order_lines.each do |line|
      next if line.ignored || line.amount == 0
      price = kc_sticker.fetch(line.product_id, 0)

      sticker += price*line.amount
      glass += price*line.amount if product_is_glass?(line.product_id)
    end
    [sticker.round(1), glass.round(1)]
  end

  def calc_stickers_for(order)
    price = sticker_price order
    CabiePio.set [:sticker, :order], order.id, price.first
    CabiePio.set [:sticker, :order_glass], order.id, price.last
  end

  def sticker_job(force = false)
    CabiePio.clear(:sticker, :order) if force
    orders = Order.all
    orders.each do |t|
      calc_stickers_for(t)
    end
  end

  def dfsmax
    Array(1..KSM::OrderStatus::BIT_DRAFTS_MAX).join(',')
  end

  def dfsru
    wonderbox(:draftstatus_ru).values
  end

  def my_order_total order
    return order.total unless current_account.limited_orders?
    section = KSM::Section.all.detect{|s|s.ix == current_account.section_id}.id
    order.sumsec section
  end

  def my_done_total order
    return order.done_total unless current_account.limited_orders?
    section = KSM::Section.all.detect{|s|s.ix == current_account.section_id}.id
    order.sumsec section, :done_total
  end
end
