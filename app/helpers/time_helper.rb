Fenix::App.helpers do
  # include CalendarHelper

  def to_msk_full(time)
    time.in_time_zone(MY_TZ).strftime('%e %b %Y / %H:%M')
  end

  def to_msk(time)
    time.in_time_zone(MY_TZ).strftime('%e %b %Y')
  end

  def to_msk_print(time)
    time.in_time_zone(MY_TZ).strftime('%Y-%m-%e, %H:%M')
  end

  def to_inv_date(datetime)
    datetime.in_time_zone(MY_TZ).strftime('%e.%m.%Y')
  end

  def to_dm(time)
    time.strftime('%-d.%m')
  end

  def to_percent(all, done)
    all > 0 ? "%0.f" % ((done.to_f/all.to_f)*100).round : 0
  end
end

class Date
  DAYNAMESRU = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'].freeze
end