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

  def save_sticker_line(ol_id, sticker)
    CabiePio.set [:m, :order_lines, :sticker], ol_id, { t: timeline_id, v: sticker}
    olsize = CabiePio.length [:m, :order_lines, :sticker], ol_id
    CabiePio.set [:m, :order_lines, :sticker], "#{ol_id}_#{olsize+1}", { t: timeline_id, v: sticker}
  end

  def save_sticker_history(order, perc, date = Date.today)
    data = CabiePio.get([:m, :sticker, :order_history], order).data || {}
    data[timeline_id(date)] = perc.round(1)
    CabiePio.set [:m, :sticker, :order_history], order, data
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
end
