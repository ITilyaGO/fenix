module Fenix::App::StickerHelper
  # def timeline_id(date = Date.today)
  #   date.strftime('%y%m%d')
  # end

  # def timeline_order(order, date = Date.today)
  #   "#{timeline_id(date)}_#{order}"
  # end

  # def timeline_unf(string)
  #   Date.parse(string[0...6])
  # end

  # def timeline_form(string)
  #   timeline_unf(string) rescue ''
  # end

  # def timeline_group(hash, dates = nil)
  #   prev = Date.today.beginning_of_week
  #   prev_end = prev.end_of_week
  #   hash.group_by {|x| timeline_unf(x.first).beginning_of_week }
  # end

  # def calendar_group(hash, dates = nil)
  #   prev = Date.today.beginning_of_week
  #   prev_end = prev.end_of_week
  #   hash.group_by {|x| timeline_unf(x.first) }
  # end

  def sticker_order_progress(order_id)
    CabiePio.get([:sticker, :order_progress], order_id).data.to_f
  end  

  def save_sticker_line(ol_id, sticker, day)
    # CabiePio.set [:m, :order_lines, :sticker], ol_id, { t: timeline_id(day), v: sticker}
    # olsize = CabiePio.length [:m, :order_lines, :sticker], ol_id
    CabiePio.set [:m, :order_lines, :sticker], "#{ol_id}_#{timeline_id(day)}", { t: timeline_id(day), v: sticker}

    sall = CabiePio.all([:m, :order_lines, :sticker], ["#{ol_id}_"]).flat
    pall = sall.sum{|k,v|v[:v]}
    last_day = sall.values.map{|e|e[:t]}.last
    CabiePio.set [:m, :order_lines, :sticker_sum], ol_id, { t: last_day, v: pall}
  end

  def save_sticker_history(order, perc, date = Date.today)
    data = CabiePio.get([:m, :sticker, :order_history], order).data || {}
    data[timeline_id(date)] = perc.round(1)
    CabiePio.set [:m, :sticker, :order_history], order, data

    CabiePio.set [:i, :orders, :sticker_date], "#{timeline_id(date)}_#{order}", 1
  end

  def save_sticker_progress(order, perc)
    CabiePio.set [:sticker, :order_progress], order, perc.round(1)
  end

  def save_stickers_amount(order, count)
    CabiePio.set [:orders, :stickers_amount], order, count.round(1)
  end
  # def calendar_busy(date)
  #   field = @ctm.fetch(date, nil)
  #   true if field.present? && field.size > 3
  # end

  # def calendar_unbusy(date)
  #   field = @ctm.fetch(date, nil)
  #   true if field.present? && field.size <= 3
  # end

  # def calendar_busy?(date)
  #   field = @ctm.fetch(date, nil)
  #   return :usual unless field.present?
  #   ids = field.map(&:last)
  #   cplx_ary = complex_hash.select {|k| ids.include?(k)}
  #   cplx_sum = cplx_ary.values.map(&:to_i).sum
  #   return :busy if cplx_sum >= wonderbox(:complexity, :level)
  #   :unbusy if cplx_sum < wonderbox(:complexity, :level)
  # end

  # def timeline_busy?(date)
  #   field = @ctm.fetch(date, nil)
  #   return :usual unless field.present?
  #   ids = field.map(&:last)
  #   cplx_ary = complex_hash.select {|k| ids.include?(k)}
  #   cplx_sum = cplx_ary.values.map(&:to_i).sum
  #   return :busy if cplx_sum >= wonderbox(:complexity, :level)
  #   :unbusy if cplx_sum < wonderbox(:complexity, :level)
  # end

  def calc_sticker_sum(ol)
    kc_products = CabiePio.all_keys(ol.map{|e|e.product_id}, folder: [:products, :sticker]).flat.trans(:to_i, :to_f)
    all = 0
    ol.each do |line|
      sall = CabiePio.all([:m, :order_lines, :sticker], ["#{line.id}_"]).flat
      next if sall.empty?
      pall = sall.sum{|k,v|v[:v]*kc_products.fetch(line.product_id, 0)}
      all += pall
    end
    all
  end

  def calc_sticker_sum_for_day(ol, day)
    kc_products = CabiePio.all_keys(ol.map{|e|e.product_id}, folder: [:products, :sticker]).flat.trans(:to_i, :to_f)
    all = 0
    ol.each do |line|
      st = CabiePio.get([:m, :order_lines, :sticker], "#{line.id}_#{timeline_id(day)}").data[:v] rescue 0
      dayprice = st*kc_products.fetch(line.product_id, 0)
      all += dayprice
    end
    all
  end

  def stickday_busy?(money)
    mil = wonderbox(:stickday_threshold, :level)
    mal = wonderbox(:stickday_threshold, :limit)

    return :busy if money >= mal
    return :unsure if money < mal && money >= mil
    :unbusy if money < mil
  end

  def save_stickday_automatic
    history = CabiePio.folder(:m, :sticker, :order_history).flat
    history.each do |k, val|
      day = val.detect{|k,v|v>0}&.first
      next unless day
      CabiePio.set [:stickday, :order], timeline_order(k, timeline_unf(day)), k
      CabiePio.set [:orders, :stickday], k, day
    end
  end
end
