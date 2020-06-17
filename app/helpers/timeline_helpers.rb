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

  def timeline_group(hash, dates = nil)
    prev = Date.today.beginning_of_week
    prev_end = prev.end_of_week
    hash.group_by {|x| timeline_unf(x.first).beginning_of_week }
  end

  def calendar_group(hash, dates = nil)
    prev = Date.today.beginning_of_week
    prev_end = prev.end_of_week
    hash.group_by {|x| timeline_unf(x.first) }
  end

  def calendar_init(start_from = Date.today)
    ky_month_1 = start_from.strftime('%y%m')
    ky_month_2 = start_from.next_month.strftime('%y%m')
    @ktm = CabiePio.all([:timeline, :order], [ky_month_1]).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], [ky_month_2]).flat
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
    return :busy if cplx_sum >= wonderbox(:complexity, :level)
    :unbusy if cplx_sum < wonderbox(:complexity, :level)
  end

  def timeline_busy?(date)
    field = @ctm.fetch(date, nil)
    return :usual unless field.present?
    ids = field.map(&:last)
    cplx_ary = complex_hash.select {|k| ids.include?(k)}
    cplx_sum = cplx_ary.values.map(&:to_i).sum
    return :busy if cplx_sum >= wonderbox(:complexity, :level)
    :unbusy if cplx_sum < wonderbox(:complexity, :level)
  end
end
