Fenix::App.helpers do
  PAGESIZE = 20.0

  def paginate
    # @page = page
    # @pages = pages
    # @c = c
    # @m = m
    # @r = route
    partial "layouts/paginate"
  end
end