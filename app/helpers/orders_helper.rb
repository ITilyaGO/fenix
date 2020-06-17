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

  def to_rub(value)
    ("%.2f" % value).gsub('.', ',')
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
end
