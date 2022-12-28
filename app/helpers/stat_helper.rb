module Fenix::App::StatHelper
  def sum_by_sections(order_ids)
    sec_sums = {}
    owol = Order.includes(:order_lines_ar).where(id: order_ids)
    KSM::Section.all.each do |s|
      sec_sums[s.ix] = owol.map do |o|
        o.order_lines.map do |ol|
          pcat = category_matrix[products_hash[ol.product_id]]
          csec = all_catagories.detect{|c|c.id == pcat}&.section_id
          csec == s.id ? ol.price*ol.amount : 0
        end.sum
      end.sum
    end
    sec_sums
  end

  def sum_done_by_sections(order_ids)
    sec_sums = {}
    owol = Order.includes(:order_lines_ar).where(id: order_ids)
    KSM::Section.all.each do |s|
      sec_sums[s.ix] = owol.map do |o|
        o.order_lines.map do |ol|
          next 0 if ol.ignored
          pcat = category_matrix[products_hash[ol.product_id]]
          csec = all_catagories.detect{|c|c.id == pcat}&.section_id
          csec == s.id ? ol.price*(ol.done_amount||0) : 0
        end.sum
      end.sum
    end
    sec_sums
  end

  def sum_by_delivery(orders)
    sums = {}
    Order.deliveries.each do |d, di|
      sums[d.to_sym] = orders.select{|o|o.delivery.to_sym == d.to_sym}.map(&:total).compact.sum
    end
    sums
  end

  def my_sum_by_delivery(orders)
    return sum_by_delivery orders unless current_account.section_id
    cas = KSM::Section.all.detect{ |s| s.ix == current_account.section_id }
    sums = {}
    Order.deliveries.each do |d, di|
      sums[d.to_sym] = orders
        .select{|o|o.delivery.to_sym == d.to_sym}
        # .sum{|o| o.sumsecd(cas.id, :total, d.to_sym) }
        .sum{ |o| my_order_total(o) || 0 }
    end
    sums
  end

  def my_total_sum_for orders
    return orders.map(&:total).compact.sum unless current_account.limited_orders?
    orders.map{ |order| my_order_total order }.compact.sum
  end

  def orders_to_cities_by_year y
    start_date = Date.new y, 1, 1
    end_date = start_date.next_year
    orders = Order.where(status: Order.statuses[:finished])
      .where('updated_at >= ?', start_date).where('updated_at < ?', end_date)
      .pluck(:id)
  end

  def orders_by_client_by_year y, cid
    start_date = Date.new y, 1, 1
    end_date = start_date.next_year
    orders = Order.where(status: Order.statuses[:finished])
      .where('updated_at >= ?', start_date).where('updated_at < ?', end_date)
      .where(client: cid)
      .pluck(:id)
  end
end