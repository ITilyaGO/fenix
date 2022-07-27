Fenix::App.helpers do
  # include CalendarHelper

  def to_msk_full(time)
    time.in_time_zone(MY_TZ).strftime('%e %b %Y / %H:%M')
  end

  def to_msk(time)
    time.in_time_zone(MY_TZ).strftime('%e %b %Y')
  end

  def to_msk_short(time)
    time.in_time_zone(MY_TZ).strftime('%e %b')
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

  def to_perc(all, done)
    all > 0 ? ((done.to_f/all.to_f)*100) : 0
  end

  def shortday(day)
    today = Date.today
    tom = { today => 'сегодня', today-1 => 'вчера' }
    today == day || today-1 == day ? tom[day] : Date::DAYNAMESRU[day.wday-1]
  end

  def smartday(day)
    today = Date.today
    return day.year unless today.year == day.year
    tom = { today => 'сегодня', today-1 => 'вчера', today+1 => 'завтра' }
    [today, today-1, today+1].include?(day) ? tom[day] : Date::DAYNAMESRU[day.wday-1]
  end

  def domiday(day)
    today = Date.today
    today.year == day.year && today.month == day.month ? day.strftime('%d') : day.strftime('%d.%m')
  end
end

class Date
  DAYNAMESRU = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'].freeze
  BOW = 2
end