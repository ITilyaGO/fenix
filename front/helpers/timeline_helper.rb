module Front::App::TimelineHelper
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
end

class Front::App
  helpers TimelineHelper
end