Fenix::App.helpers do
  include CalendarHelper

  def to_msk(time)
    time.in_time_zone(4).strftime('%e %b %Y / %H:%M')
  end

  def to_msk_date(time)
    time.in_time_zone(4).strftime('%e %b %Y')
  end

  def to_dm(time)
    time.strftime('%-d.%m')
  end

  def to_percent(all, done)
    all > 0 ? "%0.f" % ((done.to_f/all.to_f)*100).round : 0
  end
end
