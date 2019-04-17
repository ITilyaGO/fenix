Fenix::App.helpers do
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
end
