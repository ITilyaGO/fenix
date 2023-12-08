Fenix::App.controllers :prefs do

  #TODO: refactor to post requests!!!

  get :ktimeline do
    # @ktm = CabiePio.query('p/timeline/order>1904', :type => :regex).inspect
    @ktm = CabiePio.all([:timeline, :order], ['1903']).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], ['1904']).flat

    @time = Timeline.all
    render "list/timeline"
  end

  get :complex_migrate, :map => 'list/complex/migrate' do
    @time = Order.all
    CabiePio.clear(:complexity, :order)
    @time.each do |t|
      CabiePio.set [:complexity, :order], t.id, calc_complexity_for(t)
    end
    render "list/complex"
  end

  get :box, :map => 'list/box' do
    # wonderbox_set(:complex_level, 512)
    # wonderbox_set(:complexity, { level: 256, limit: 512, unbusy: 6 })
    render "list/complex"
  end
  get :page do
    @title = t 'tit.prefs.page'
    render 'prefs/page'
  end

  get :levels do
    @title = t 'tit.prefs.page'
    render 'prefs/levels'
  end

  put :stick_limits do
    wonderbox_set(:stickday_limit, params[:limit].to_i)
    # wonderbox_set(:stickday_threshold, params[:stickday_threshold].transform_values(&:to_i))

    redirect url(:timeline, :stickdays)
  end

  patch :stickday_info do
    @cdate = timeline_unf(params[:date]) rescue Date.today

    ky_day = @cdate.strftime('%y%m%d')
    @tml = CabiePio.all([:stickday, :order], [ky_day]).flat

    @all_ids = @tml.map(&:last).map(&:to_i)
    @orders = Order.where(id: @all_ids).order(:client_id)
    @stickers = CabiePio.all_keys(@all_ids, folder: [:sticker, :order_progress]).flat.trans(:to_i, :to_f)
    @day = KSM::StickdayLimit.find(@cdate).rebase(wonderbox(:stickday_limit))

    partial 'prefs/stickday/info'
  end

  put :stickday_set, :with => :id do
    day = KSM::StickdayLimit.find params[:id]
    day.price = params[:price].to_i
    day.delivery = params[:delivery].to_sym
    day.delivery = nil if params[:delivery].size == 0
    day.save

    redirect url(:timeline, :stickdays)
  end

  get :stadies do
    @title = t 'tit.prefs.stadies'
    @stadies = wonderbox :stadie_grade
    @shash = wonderbox :stadie_days
    @still = wonderbox :stadie_still
    render 'prefs/stadies'
  end

  put :stadies do
    form = params[:st]
    a = form.map{|delk, delv| [delk.to_sym, delv.map{|k,v| [k.to_sym, v.to_i]}.to_h] }.to_h
    wonderbox_set :stadie_days, a
    wonderbox_set :stadie_still, params[:still].to_sym

    redirect url *%i_ prefs stadies _
  end

  get :draftstatus do
    @title = t 'tit.prefs.page'
    render 'prefs/page'
  end

  put :levels do
    wonderbox_set(:complexity, params[:complexity].transform_values(&:to_i))
    wonderbox_set(:stickday_threshold, params[:stickday_threshold].transform_values(&:to_i))

    render 'prefs/levels'
  end

  get :connector do
    @title = t 'tit.prefs.conn'
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    @archs = KSM::Archetype.all
    @grouped = @archs.group_by{|a|a.category_id.to_i}
    @squadconf = wonderbox(:bbconnector) || {}
    render 'prefs/conn'
  end

  post :connector do
    form = params[:supermodel]
    ena = params[:run] == '1'
    data = { url: form[:url], run: ena }
    wonderbox_set(:bbconnector, data)
    
    redirect url(:prefs, :connector)
  end

  get :export_products_1c do
    @title = 'Выгрузка продуктов 1C'
    @cats = KSM::Category.toplevel.sort_by(&:wfindex)
    @r = url(:prefs, :export_products_1c)
    render 'prefs/export_products_1c'
  end

  post :export_products_1c do
    @cats = KSM::Category.toplevel.sort_by(&:wfindex)
    if params[:cat] == 'all' && params[:place] == 'all' && params[:search].empty?
      @products = Product.all
    else
      products_by_filters(params)
    end

    if params[:download_button].nil?
      @title = 'Выгрузка продуктов 1C'
      @r = url(:prefs, :export_products_1c)
      render 'prefs/export_products_1c'
    else
      headers['Content-Disposition'] = "attachment; filename=pio-products-to-1c cat_#{params[:cat]} place_#{params[:place]}.json"
      headers['Content-Type'] = "application/json"
      output = Json1CAssist.ProductsToJson(@products).force_encoding('utf-8')
    end
  end

end