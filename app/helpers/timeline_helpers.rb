module Fenix::App::TimelineHelper
  def timeline_id(date = Date.today)
    date.strftime('%y%m%d')
  end

  def timeline_order(order, date = Date.today)
    "#{timeline_id(date)}_#{order}"
  end

  def timeline_unf(string)
    Date.parse(string[0...6])
  end

  def timeline_form(string)
    timeline_unf(string) rescue ''
  end

  def timeline_months(end_date, start_date = Date.today)
    count = (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
    from = count < 0 ? end_date : start_date 
    ary = [shortline_id(start_date), shortline_id(end_date)]
    count.abs.times do |i|
      ary << shortline_id(from.next_month(i))
    end
    ary.uniq.sort
  end

  def shortline_id(date = Date.today)
    date.strftime('%y%m')
  end  

  def timeline_group(hash, dates = nil)
    # prev = Date.today.beginning_of_week
    # prev_end = prev.end_of_week
    hash.group_by {|x| (timeline_unf(x.first) - Date::BOW).beginning_of_week + Date::BOW }
  end

  def calendar_group(hash, dates = nil)
    prev = Date.today.beginning_of_week
    prev_end = prev.end_of_week
    hash.group_by {|x| timeline_unf(x.first) }
  end

  def calendar_init(start_from = Date.today)
    ky_month_1 = start_from.strftime('%y%m')
    ky_month_2 = start_from.next_month.strftime('%y%m')
    ky_month_0 = start_from.prev_month.strftime('%y%m')
    @ktm = CabiePio.all([:timeline, :order], [ky_month_1]).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], [ky_month_2]).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], [ky_month_0]).flat
    @ctm = calendar_group(@ktm)
  end

  # def calendar_busy(date)
  #   field = @ctm.fetch(date, nil)
  #   true if field.present? && field.size > 3
  # end

  # def calendar_unbusy(date)
  #   field = @ctm.fetch(date, nil)
  #   true if field.present? && field.size <= 3
  # end

  def calendar_busy?(date)
    field = @ctm.fetch(date, nil)
    return :usual unless field.present?
    ids = field.map(&:last)
    cplx_ary = complex_hash.select {|k| ids.include?(k)}
    cplx_sum = cplx_ary.values.map(&:to_i).sum
    thr = wonderbox(:complexity, :level)
    thr2 = wonderbox(:complexity, :limit)
    return :busy if cplx_sum >= thr2
    return :unsure if cplx_sum >= thr && cplx_sum < thr2
    :unbusy if cplx_sum < thr
  end

  def timeline_busy?(date)
    field = @ctm.fetch(date, nil)
    return :usual unless field.present?
    ids = field.map(&:last)
    cplx_ary = complex_hash.select {|k| ids.include?(k)}
    cplx_sum = cplx_ary.values.map(&:to_i).sum
    thr = wonderbox(:complexity, :level)
    thr2 = wonderbox(:complexity, :limit)
    return :busy if cplx_sum >= thr2
    return :unsure if cplx_sum >= thr && cplx_sum < thr2
    :unbusy if cplx_sum < thr
  end

  def stadie_gap order
    om = Order.find order
    deli = om.delivery.to_sym
    std = wonderbox(:stadie_days).fetch(deli, {})
    std.values.sum
  end

  def stadie_pregap order
    om = Order.find order
    deli = om.delivery.to_sym
    items = wonderbox :stadie_grade
    still = wonderbox :stadie_still
    items = items[0...items.index(still)]
    std = wonderbox(:stadie_days).fetch(deli, {})
    items.map(&std).sum
  end

  def stadie_done order
    om = Order.find order
    deli = om.delivery.to_sym
    orderstill = CabiePio.get(%i(m sticker days), om.id).data
    return nil unless orderstill
    items = wonderbox :stadie_grade
    still = wonderbox :stadie_still
    items = items[items.index(still)+1..-1]
    std = wonderbox(:stadie_days).fetch(deli, {})
    gap = items.map(&std).sum
    orderstill.keys.last + gap
  end
end
