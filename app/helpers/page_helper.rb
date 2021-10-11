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

  def local hash
    url(*@ra||[:orders, :index], **@rah||{}, **hash)
  end

  def tj *args
    t args.join('.')
  end

  def tja *args
    (tj *args).first
  end
end