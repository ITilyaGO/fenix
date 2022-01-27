Fenix::App.controllers :statistic do
  STAT_YEARLY_GAP = 3.freeze
  STAT_MONTHLY_GAP = 5.freeze

  get :index do
    @title = "Statistics"
    render 'statistic/index'
  end

  get :cities do
    @title = "Statistics - все известные заказы"
    @stat = Order.joins(:place).group(:place_id, "places.name").order("count(*) desc", "places.name").count(:id)
    render 'statistic/cities'
  end

  get :bycity, :with => :id do
    @title = "Statistics - все известные заказы"
    @city = Place.find(params[:id])
    @orders = Order.where(:place_id => @city.id).pluck(:id)
    stat = OrderLine.where(order_id: @orders).joins(:product, :product => :category).group(:product_id, "products.'index'", "categories.'index'").order("categories_index", "products_index").sum(:amount)
    @pretty_stat = []
    stat.each do |item|
      pid = item[0][0]
      p = Product.find(item[0][0])
      @pretty_stat << { :id => pid, :category => p.category.name, :name => p.displayname, :sum => item[1] }
    end
    render 'statistic/bycity'
  end

  get :kcities, :with => :year do
    @title = "Statistics - все известные заказы"
    # @stat = Order.joins(:place).group(:place_id, "places.name").order("count(*) desc", "places.name").count(:id)
    render 'statistic/kcities'
  end

  put :kcities_boot, :with => :year do
    time = sec do
      ids = orders_to_cities_by_year params[:year].to_i
      kc_orders = CabiePio.all_keys(ids, folder: [:orders, :towns]).flat
      @res = kc_orders.group_by(&:last).transform_values{|a|a.map(&:first).map(&:to_i)}
    end
    # wk = "stat_#{params[:year]}".to_sym
    # wonderbox_set wk, @res
    @stat = [Thread.current.inspect]
    @time = notice_for_time(time)
    {
      time: @time,
      res: @res
    }.to_json
  end

  put :kcities, :with => :year do
    time = sec do
      ids = orders_to_cities_by_year params[:year].to_i
      kc_orders = CabiePio.all_keys(ids, folder: [:orders, :towns]).flat
      @res = kc_orders.group_by(&:last).transform_values{|a|a.map(&:first).map(&:to_i)}
    end
    # wk = "stat_#{params[:year]}".to_sym
    # wonderbox_set wk, @res
    @stat = [Thread.current.inspect]
    @time = notice_for_time(time)
    
    partial 'statistic/kcities_list'
  end

  get :bykcity, map: 'statistic/bykcity/:year/:city' do
    @title = "Statistics - по городу за год"
    @city = KatoAPI.anything(params[:city]).model
    ids = orders_to_cities_by_year params[:year].to_i
    kc_orders = CabiePio.all_keys(ids, folder: [:orders, :towns]).flat
    @res = kc_orders.group_by(&:last).transform_values{|a|a.map(&:first).map(&:to_i)}

    @orders = @res.fetch(params[:city], [])
    stat = OrderLine.where(order_id: @orders)
      .joins(:product, :product => :category)
      .group(:product_id, "products.'index'", "categories.'index'")
      .order("categories_index", "products_index")
      .sum(:done_amount)
    @pretty_stat = []
    stat.each do |item|
      pid = item[0][0]
      p = Product.find(item[0][0])
      @pretty_stat << { :id => pid, :category => p.category.name, :price => p.price, :name => p.displayname, :sum => item[1] }
    end
    render 'statistic/bycity'
  end

  get :byclients, map: 'statistic/byclients/:year/:city' do
    @title = "Statistics - по городу за год"
    @city = KatoAPI.anything(params[:city]).model
    ids = orders_to_cities_by_year params[:year].to_i
    kc_orders = CabiePio.all_keys(ids, folder: [:orders, :towns]).flat
    @res = kc_orders.group_by(&:last).transform_values{|a|a.map(&:first).map(&:to_i)}

    @orders = @res.fetch(params[:city], [])
    @gpretty_stat = Order.where(id: @orders)
      .joins(:client)
      .group(:client_id)
      .order('sum(orders.done_total) DESC')
      .pluck(:client_id, 'sum(orders.done_total), sum(orders.total), count(*)')

    render 'statistic/clients_bycity'
  end

  get :byclient, map: 'statistic/byclient/:year/:city/:client' do
    @title = "Statistics - по клиенту за год"
    @city = KatoAPI.anything(params[:city]).model
    @client = Client.find params[:client]
    ids = orders_by_client_by_year params[:year].to_i, @client.id
    kc_orders = CabiePio.all_keys(ids, folder: [:orders, :towns]).flat
    @res = kc_orders.group_by(&:last).transform_values{|a|a.map(&:first).map(&:to_i)}

    @orders = @res.fetch(params[:city], [])
    stat = OrderLine.where(order_id: @orders)
      .joins(:product, :product => :category)
      .group(:product_id, "products.'index'", "categories.'index'")
      .order("categories_index", "products_index")
      .sum(:done_amount)
    @pretty_stat = []
    stat.each do |item|
      pid = item[0][0]
      p = Product.find(item[0][0])
      @pretty_stat << { :id => pid, :category => p.category.name, :price => p.price, :name => p.displayname, :sum => item[1] }
    end
    render 'statistic/byclient'
  end

  get :orders do
    @title = "Statistics - текущие заказы"
    @cats = Category.where(:category_id => nil)
    render 'statistic/index_orders'
  end

  get :orders, :with => :id, :provides => [:html, :csv] do
    @title = "Statistics - текущие заказы"
    id = params[:id]
    @orders = Order.where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished])
    stat = OrderLine.where(order_id: @orders).where('"categories"."category_id" = %s', id).joins(:product, :product => :category).group(:product_id, "products.'index'", "categories.'index'").order("categories_index", "products_index").sum(:amount)
    @pretty_stat = []
    stat.each do |item|
      pid = item[0][0]
      p = Product.find(item[0][0])
      @pretty_stat << { :id => pid, :category => p.category.name, :name => p.displayname, :sum => item[1] }
    end
    @category = Category.find(id)
    
    case content_type
      when :html then render 'statistic/orders'
      when :csv then begin
        fname = 'statistics-' + @category.name + '.csv'
        headers['Content-Disposition'] = "attachment; filename=#{fname}"
        output = ''
        output = "\xEF\xBB\xBF" if params.include? :win
        output << CSV.generate(:col_sep => ';') do |csv|
          # csv << "\xEF\xBB\xBF" if params[:win]
          # csv << %w(id name num)
          @pretty_stat.each do |item|
            csv << [item[:category].encode('utf-8'), item[:name].encode('utf-8'), item[:sum]]
          end
        end
      end
    end

    # respond_to do |format|
    #   format.html render 'statistic/orders'
    #   format.csv do
    #     @stat1 = params[:all].present?
    #   end
    #   # format.csv { render :csv => csv_string, :filename => "myfile.csv" }
    # end
  end

  get :orders_frame_start do
    from = timeline_id Date.today-3
    to = timeline_id Date.today
    redirect url(:statistic, :orders_frame, :from => from, :to => to)
  end

  post :orders_frame_start do
    redirect url(:statistic, :orders_frame, :from => params[:from], :to => params[:to])
  end

  get :orders_frame, :provides => [:html, :csv] do
    @title = "Statistics - текущие заказы"
    id = params[:id]
    @from = timeline_unf params[:from]
    @to = timeline_unf params[:to]
    too_much = (@to-@from).ceil > 31
    if too_much
      @pretty_stat = @orders = []
      flash[:warning] = 'больше 30 дней'
      return render 'statistic/orders_frame'
    end
    dary = @from.step(@to).map{|d|timeline_id(d)}
    oids = []
    dary.each do |date|
      oids << CabiePio.all([:anewdate, :order], [date]).flat.values.map(&:to_i)
    end
    @orders = Order.where(id: oids)
    stat = OrderLine.where(order_id: @orders)
      .joins(:product, :product => :category)
      .group(:product_id, "products.'index'", "categories.'index'")
      .order("categories_index", "products_index")
      .sum(:amount)
    @pretty_stat = []
    stat.each do |item|
      pid = item[0][0]
      p = Product.find(item[0][0])
      @pretty_stat << { :id => pid, :category => p.category.name, :name => p.displayname, :sum => item[1] }
    end
    
    case content_type
      when :html then render 'statistic/orders_frame'
      when :csv then begin
        fname = 'statistics-' + @category.name + '.csv'
        headers['Content-Disposition'] = "attachment; filename=#{fname}"
        output = ''
        output = "\xEF\xBB\xBF" if params.include? :win
        output << CSV.generate(:col_sep => ';') do |csv|
          # csv << "\xEF\xBB\xBF" if params[:win]
          # csv << %w(id name num)
          @pretty_stat.each do |item|
            csv << [item[:category].encode('utf-8'), item[:name].encode('utf-8'), item[:sum]]
          end
        end
      end
    end
  end

  get :stickers_frame_start do
    from = timeline_id Date.today-3
    to = timeline_id Date.today
    redirect url(:statistic, :stickers_frame, :from => from, :to => to)
  end

  post :stickers_frame_start do
    redirect url(:statistic, :stickers_frame, :from => params[:from], :to => params[:to])
  end

  get :stickers_frame, :provides => [:html, :csv] do
    @title = "Statistics - клейка за период"
    id = params[:id]
    @from = timeline_unf params[:from]
    @to = timeline_unf params[:to]
    too_much = (@to-@from).ceil > 31
    if too_much
      @pretty_stat = @orders = []
      flash[:warning] = 'больше 30 дней'
      return render 'statistic/stickers_frame'
    end
    dary = @from.step(@to).map{|d|timeline_id(d)}
    ols = []
    dary.each do |date|
      ols << CabiePio.query("m/order_lines/sticker>.*_#{date}", type: :regex).records
    end
    olids = ols.flatten.map{|a|a.key.public.split('_').first.to_i}.uniq
    op = OrderLine.where(id: olids).pluck(:id, :product_id).to_h
    olsum = ols.flatten.group_by{|a|op.fetch a.key.public.split('_').first.to_i, nil}
    
    @pretty_stat = []
    olsum.each do |pid,items|
      p = Product.find(pid)
      @pretty_stat << { :id => pid, :category => p.category.name, :name => p.displayname, :sum => items.sum{|a|a.data[:v]} }
    end

    case content_type
      when :html then render 'statistic/stickers_frame'
      when :csv then begin
        fname = 'stickers-' + @category.name + '.csv'
        headers['Content-Disposition'] = "attachment; filename=#{fname}"
        output = ''
        output = "\xEF\xBB\xBF" if params.include? :win
        output << CSV.generate(:col_sep => ';') do |csv|
          # csv << "\xEF\xBB\xBF" if params[:win]
          # csv << %w(id name num)
          @pretty_stat.each do |item|
            csv << [item[:category].encode('utf-8'), item[:name].encode('utf-8'), item[:sum]]
          end
        end
      end
    end
  end

  get :finished do
    @title = "Statistics - готовые заказы"
    @cats = Category.where(:category_id => nil)
    @months = []
    start_date = Date.new(Date.today.year, Date.today.month, 1)

    STAT_MONTHLY_GAP.times do |i|
      @months << start_date.prev_month(STAT_MONTHLY_GAP-1-i).strftime("%b %y")
    end
    render 'statistic/index_finished'
  end

  get :finished, :with => :id, :provides => [:html, :csv] do
    @title = "Statistics - готовые заказы"
    id = params[:id]
    gap = params[:gap].to_i
    today = Date.today.next_month -gap
    @start_date = Date.new(today.year, today.month, 1)
    end_date = @start_date.next_month
    ignored = YAML.load_file('./stat_ignore.yml') rescue []
    @orders = Order.where(status: Order.statuses[:finished])
      .where('updated_at >= ?', @start_date).where('updated_at < ?', end_date)
      .where.not(client_id: ignored)
    stat = OrderLine.where(order_id: @orders, ignored: false).where('"categories"."category_id" = %s', id)
      .joins(:product, :product => :category)
      .group(:product_id, "products.'index'", "categories.'index'")
      .order("categories_index", "products_index").sum(:done_amount)
    @pretty_stat = []
    stat.each do |item|
      pid = item[0][0]
      p = Product.find(pid)
      @pretty_stat << { :id => pid, :category => p.category.name, :name => p.displayname, :sum => item[1] }
    end
    @category = Category.find(id)
    
    case content_type
      when :html then render 'statistic/finished'
      when :csv then begin
        fname = 'statistics-' + @category.name + '-' + @start_date.strftime("%b %y") + '.csv'
        headers['Content-Disposition'] = "attachment; filename=#{fname}"
        output = ''
        output = "\xEF\xBB\xBF" if params.include? :win
        output << CSV.generate(:col_sep => ';') do |csv|
          # csv << %w(id name num)
          @pretty_stat.each do |item|
            csv << [item[:category], item[:name], item[:sum]]
          end
        end
      end
    end
  end

  get :finished_yearly do
    @title = "Statistics - готовые заказы"
    @cats = Category.where(:category_id => nil)
    @years = []
    start_date = Date.new(Date.today.year, 1, 1)

    STAT_YEARLY_GAP.times do |i|
      @years << start_date.prev_year(STAT_YEARLY_GAP-1-i).strftime("%Y")
    end
    render 'statistic/index_finished_yearly'
  end

  get :finished_yearly, :with => :id, :provides => [:html, :csv] do
    @title = "Statistics - готовые заказы"
    id = params[:id]
    gap = params[:gap].to_i
    today = Date.today.year-gap
    @start_date = Date.new(today, 1, 1)
    end_date = @start_date.next_year
    ignored = YAML.load_file('./stat_ignore.yml') rescue []
    @orders = Order.where(status: Order.statuses[:finished])
      .where('updated_at >= ?', @start_date).where('updated_at < ?', end_date)
      .where.not(client_id: ignored)
    stat = OrderLine.where(order_id: @orders, ignored: false).where('"categories"."category_id" = %s', id)
      .joins(:product, :product => :category)
      .group(:product_id, "products.'index'", "categories.'index'")
      .order("categories_index", "products_index").sum(:done_amount)
    @pretty_stat = []
    stat.each do |item|
      pid = item[0][0]
      p = Product.find(pid)
      @pretty_stat << { :id => pid, :category => p.category.name, :name => p.displayname, :sum => item[1] }
    end
    @category = Category.find(id)
    
    case content_type
      when :html then render 'statistic/finished_yearly'
      when :csv then begin
        fname = 'statistics-' + @category.name + '-' + @start_date.strftime("%Y") + '.csv'
        headers['Content-Disposition'] = "attachment; filename=#{fname}"
        output = ''
        output = "\xEF\xBB\xBF" if params.include? :win
        output << CSV.generate(:col_sep => ';') do |csv|
          # csv << %w(id name num)
          @pretty_stat.each do |item|
            csv << [item[:category], item[:name], item[:sum]]
          end
        end
      end
    end
  end

  get :done do
    @title = "Statistics - суммы готовых за год"
    # @cats = Category.where(:category_id => nil)
    @years = []
    start_date = Date.new(Date.today.year, Date.today.month, 1)

    5.times do |i|
      @years << start_date.prev_year(4-i).strftime("%Y")
    end
    render 'statistic/index_done'
  end

  get :done, :with => :id, :provides => [:html, :csv] do
    @title = "Statistics - суммы готовых за год"
    id = params[:id].to_i
    @start_date = Date.new(id, 1, 1)
    end_date = @start_date.next_year

    @orders = Order.where(status: Order.statuses[:finished])
      .where('orders.updated_at >= ?', @start_date).where('orders.updated_at < ?', end_date)
    @stat = @orders.joins(:place).group(:place_id, "places.name").sum(:done_total)

    @pretty_stat = []
    @stat.sort_by{|item|-item[1]}.each do |item|
      @pretty_stat << { :name => item[0][1], :sum => "%0.f" % item[1] }
    end
    
    case content_type
      when :html then render 'statistic/done'
      when :csv then begin
        fname = 'statistics_done-' + @start_date.strftime("%Y") + '.csv'
        headers['Content-Disposition'] = "attachment; filename=#{fname}"
        output = ''
        output = "\xEF\xBB\xBF" if params.include? :win
        output << CSV.generate(:col_sep => ';') do |csv|
          @pretty_stat.each do |item|
            csv << [item[:name], item[:sum]]
          end
        end
      end
    end
  end
end