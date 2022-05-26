Fenix::App.controllers :archetypes do
  get :oindex do
    @title = "Archetypes"
    @cats = Category.where(category: nil).order(:index => :asc)
    @archetypes = KSM::Archetype.all
    @categories = Category.all.includes(:category)
    @kc_archs = CabiePio.folder(:product, :archetype).flat
    @archs = KSM::Archetype.all
    @grouped = @archs.group_by{|a|a.category_id.to_i}
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @r = url(:archetypes, :index)
    render 'archetypes/index'
  end

  get :products do
    @title = "Archetypes"
    @cats = Category.where(category: nil).order(:index => :asc)
    @archetypes = KSM::Archetype.all.map{|a|[a.id, a]}.to_h
    @categories = Category.all.includes(:category)
    @kc_archs = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    @kc_multi = CabiePio.folder(:product, :archetype_multi).flat.trans(:to_i, :to_i)
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    # @archetypes = Archetype.all.includes(:category).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    # @pages = (Archetype.count/pagesize).ceil
    render 'archetypes/products'
  end
  
  get :index do
    @title = t 'tit.archetypes.list'
    @arch = KSM::Archetype.new(id: -1)
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    
    render 'archetypes/listform'
  end

  get :e, :with => :id do
    @title = t 'tit.archetypes.list'
    @arch = KSM::Archetype.find(params[:id])
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    @squadconf = @arch.serializable_hash

    render 'archetypes/listform'
  end

  put :updatex, :with => :id do
  end

  get :new do
    @title = "New archetype"
    @archetype = KSM::Archetype.nest
    @archetype.save
    @cats = Category.where(:category_id => nil)
    render 'archetypes/edit'
  end
  
  put :update, :with => :id do
    @title = pat(:update_title, :model => "product #{params[:id]}")
    @archetype = KSM::Archetype.find(params[:id])
    if @archetype.exist?
      @archetype.name = params[:ksm_archetype][:name]
      @archetype.category_id = params[:ksm_archetype][:category_id].to_i
      @archetype.g = params[:ksm_archetype][:group] == '1'
      @archetype.save
    end
    redirect url(:archetypes, :index)
    if @archetype.save
      @title = pat(:create_title, :model => "archetype #{@archetype.id}")
      flash[:success] = pat(:create_success, :model => 'Archetype')
      params[:save_and_continue] ? redirect(url(:archetypes, :index)) : redirect(url(:archetypes, :edit, :id => @archetype.id))
    else
      @title = pat(:create_title, :model => 'archetype')
      flash.now[:error] = pat(:create_error, :model => 'archetype')
      render 'archetypes/new'
    end
  end
  
  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "archetype #{params[:id]}")
    @archetype = KSM::Archetype.find(params[:id])
    @cats = Category.where(:category_id => nil)
    if @archetype.exist?
      render 'archetypes/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'archetype', :id => "#{params[:id]}")
      halt 404
    end
  end

  get :assign, :with => :id do
    @title = pat(:edit_title, :model => "archetype #{params[:id]}")
    @product = Product.find(params[:id])
    @archetype = CabiePio.get([:product, :archetype], @product.id).data
    @multi = CabiePio.get([:product, :archetype_multi], @product.id).data
    @archs = KSM::Archetype.all
    @grouped = @archs.group_by{|a|a.category_id.to_i}
    @cats = Category.where(:category_id => nil)
    if @product
      render 'archetypes/assign'
    else
      flash[:warning] = pat(:create_error, :model => 'archetype', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :assign, :with => :id do
    @title = pat(:edit_title, :model => "archetype #{params[:id]}")
    @product = Product.find(params[:id])
    a = params[:garchetype].empty? ? params[:archetype] : params[:garchetype]
    @archetype = KSM::Archetype.find(a)
    if @product
      if @archetype.exist?
        CabiePio.set [:product, :archetype], @product.id, @archetype.id
        aq = params[:supermodel][:q].to_i
        aq = 1 if aq < 1
        if aq > 1
          CabiePio.set [:product, :archetype_multi], @product.id, aq
        else
          CabiePio.unset [:product, :archetype_multi], @product.id
        end
      else
        CabiePio.unset [:product, :archetype], @product.id
        CabiePio.unset [:product, :archetype_multi], @product.id
      end
      redirect url(:archetypes, :products)
    else
      flash[:warning] = pat(:create_error, :model => 'archetype', :id => "#{params[:id]}")
      halt 404
    end
  end

  get :detail, :with => :id do
    @arch = KSM::Archetype.find(params[:id])
    @olneed = CabiePio.query("p/need/order>#{@arch.id}_", type: :prefix).flat.trans(nil, :to_i)
    @need = CabiePio.get([:need, :archetype], @arch.id)
    @stock = CabiePio.get([:stock, :archetype], @arch.id)
    oids = @olneed.keys.map{|ol|ol.split('_').last}
    @orders = Order.where(id: oids)
    @kc_orders = CabiePio.all_keys(oids, folder: [:orders, :towns]).flat
    codes = @kc_orders.values.uniq
    @kc_towns = KatoAPI.batch(codes)
    @kc_status = KSM::OrderStatus.find_all(oids)
    @kc_timelines = CabiePio.all_keys(oids, folder: [:orders, :timeline]).flat.trans(:to_i)

    render 'archetypes/detail'
  end

  get :historic, :with => :id do
    @arch = KSM::Archetype.find(params[:id])
    @holders = {}
    @destocks = {}
    @dayeq = {}

    @day = Date.parse(params[:day]) rescue Date.today - 1.month
    first_day = @day + 1.month - 1
    today = @day
    @first_day = first_day
    tdays = today.step(first_day, 1)
    days = []
    dids = tdays.each_with_index.map{|_, i| archetype_daystock(@arch.id, @day+i) }
    stockdays = CabiePio.all_keys(dids, folder: [:stock, :common, :a]).flat.trans(nil, :to_i)
    destockdays = CabiePio.all_keys(dids, folder: [:stock, :common, :d]).flat.trans(nil, :to_i)

    tdays.each_with_index do |_, i|
      cday = @day+i
      @holders[cday] = stockdays.fetch(archetype_daystock(@arch.id, cday), nil)
      @destocks[cday] = destockdays.fetch(archetype_daystock(@arch.id, cday), nil)
      @dayeq[cday] = (@holders[cday]||0) - (@destocks[cday]||0)
      days << to_dm(cday)
    end
    @holders = @holders.compact
    @destocks = @destocks.compact

    @prev = @day.day == 1 ? @day - 1.month : Date.new(@day.year, @day.month, 1) + 1.month
    @next = @day + 1.month

    lines = tdays.map{|d|@dayeq[d]||0}
    polines = tdays.map{|d|-(@destocks[d]||0)}
    nelines = lines.each_with_index.map{|_,i|lines[0..i].compact.sum}
    alines = tdays.map{|d|@holders[d]||0}

    @chart = { days: days, adds: alines, rems: polines, neus: nelines, difdays: lines }

    render 'archetypes/historic'
  end

  get :stock do
    # OrderJobs.stock_job(force: true)
    @title = "Stock"
    @day = Date.parse(params[:day]) rescue Date.today
    @holders = {}
    @destocks = {}
    @olneed = {}
    ksm_arch = KSM::Archetype.all
    ar_hash = ksm_arch.map(&:id)
    ar_hash.each do |sk|
      @holders[sk] ||= {}
      @destocks[sk] ||= {}

      ol_need = CabiePio.query("p/need/order>#{sk}_", type: :prefix).flat.trans(nil, :to_i)
      @olneed[sk] = ol_need.values.sum
    end
    7.times do |i|
      dt = (@day-i).strftime('%y%m%d')
      all_ids = ar_hash.map{|p|archetype_daystock(p, @day-i)}
      stockday = CabiePio.all_keys(all_ids, folder: [:stock, :common, :a]).flat
      stockday.each do |sk, sv|
        p = sk.split('_').first
        @holders[p] ||= {}
        @holders[p][@day-i] = sv.to_i
      end
      destockday = CabiePio.all_keys(all_ids, folder: [:stock, :common, :d]).flat
      destockday.each do |sk, sv|
        p = sk.split('_').first
        @destocks[p] ||= {}
        @destocks[p][@day-i] = sv.to_i
      end
    end
        
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    @ar_grouped = ksm_arch.group_by{|a|a.category_id.to_i}
    arp = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    @kc_stocks = CabiePio.folder(:stock, :archetype).flat.trans(nil, :to_i)
    @kc_needs = CabiePio.folder(:need, :archetype).flat.trans(nil, :to_i)
    catgroup = products_hash.keys.group_by{|k|products_hash[k]}
    @catstock = catgroup.map{|k,v|[k, v.map{|p|@kc_stocks.fetch(arp[p], 0)}.sum{|x|x<0?x:0}]}.to_h
    @catneed = catgroup.map{|k,v|[k, v.map{|p|@kc_needs.fetch(arp[p], 0)}.sum{|x|x>0?x:0}]}.to_h
    @kc_archs = arp

    @products = Product.all
    @kc_index = arp.map{|p, a| [a, @products.detect{|i|i.id == p}&.index || 0]}.to_h

    render 'archetypes/stock'
  end

  put :stock do
    params[:lines]&.each do |k, line|
      line.each do |date, stock_in|

        # stock_in = line['in']
        # stock_out = line['out']
        id = k
        day = Time.parse date
        next if stock_in.size == 0
        # stock_in = date.last
        # id = k

        prev_day = CabiePio.get([:stock, :common, :a], archetype_daystock(id, day)).data.to_i
        CabiePio.set [:stock, :common, :a], archetype_daystock(id, day), stock_in.to_i if stock_in.size > 0
        # CabiePio.set [:stock, :common, :n], product_daystock(id), stock_out.to_i if stock_out.size > 0

        # diff = stock_in.to_i - stock_out.to_i
        # if diff != 0
        sum = CabiePio.get [:stock, :archetype], id
        CabiePio.set [:stock, :archetype], id, sum.data.to_i + stock_in.to_i - prev_day
      end
    end

    redirect url(:archetypes, :stock)
  end
  
  get :stock_clean do
    ol_need = CabiePio.folder(:need, :order).flat
    oids = ol_need.keys.map{|r|r.split('_').last}.uniq
    os = oids.map{|id|KSM::OrderStatus.find(id)}
      .select{|o|!o.exist?||o.what?(:finished)||o.what?(:shipped)||o.what?(:canceled)||o.what?(:draft)}
    
    @os = os
    render 'archetypes/stock_clean'
  end
  
  put :stock_clean do
    ol_need = CabiePio.folder(:need, :order).flat
    oids = ol_need.keys.map{|r|r.split('_').last}.uniq
    os = oids.map{|id|KSM::OrderStatus.find(id)}
      .select{|o|!o.exist?||o.what?(:finished)||o.what?(:shipped)||o.what?(:canceled)||o.what?(:draft)}
    
    os.each{|s|arbal_need_order_rep(s)}
    redirect url(:archetypes, :stock_clean)
  end
  
  post :list, :provides => :json do
    @archs = KSM::Archetype.all
    cat = params[:cat].to_i
    products = @archs.select{|a|a.category_id == cat}.map(&:to_r)
    products.to_json
  end

  put :bbtie, :provides => :json do
    arch = KSM::Archetype.find params[:left]
    return {}.to_json unless arch.exist?
    arch.bbid = params[:right]
    arch.save
    {}.to_json
  end
end