Fenix::App.helpers do
  PAGESIZE = 20.0

  def paginate opts=nil
    # @page = page
    # @pages = pages
    # @c = c
    # @m = m
    # @r = route
    @rah = opts if opts
    partial "layouts/paginate"
  end

  def local hash
    url(*@ra||[:orders, :index], **@rah||{}, **hash.compact)
  end

  def localr hash
    @ra = @r.split('?').first.split('/')[1..-1].map(&:to_sym)
    @ra << :index if @ra.size < 2
    url(*@ra, **(hash.merge(@rah||{})).compact)
  end

  def tj *args
    t args.join('.')
  end

  def tja *args
    (tj *args).first
  end
end