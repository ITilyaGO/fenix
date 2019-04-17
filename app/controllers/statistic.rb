Fenix::App.controllers :statistic do
  require 'csv'

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
        CSV.generate(:col_sep => ';') do |csv|
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

  get :finished do
    @title = "Statistics - готовые заказы"
    @cats = Category.where(:category_id => nil)
    @months = []
    start_date = Date.new(Date.today.year, Date.today.month, 1)

    5.times do |i|
      @months << start_date.prev_month(4-i).strftime("%b %y")
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
    @orders = Order.where(status: Order.statuses[:finished]).where('updated_at >= ?', @start_date).where('updated_at < ?', end_date)
    stat = OrderLine.where(order_id: @orders, ignored: false).where('"categories"."category_id" = %s', id).joins(:product, :product => :category).group(:product_id, "products.'index'", "categories.'index'").order("categories_index", "products_index").sum(:done_amount)
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
        CSV.generate(:col_sep => ';') do |csv|
          # csv << %w(id name num)
          @pretty_stat.each do |item|
            csv << [item[:category], item[:name], item[:sum]]
          end
        end
      end
    end
  end
end