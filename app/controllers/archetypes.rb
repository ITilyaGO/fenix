Fenix::App.controllers :archetypes do
  get :index do
    @title = "Archetypes"
    @cats = Category.where(category: nil).order(:index => :asc)
    @archetypes = KSM::Archetype.all
    @categories = Category.all.includes(:category)
    @kc_archs = CabiePio.folder(:product, :archetype).flat
    @archs = KSM::Archetype.all
    @grouped = @archs.group_by{|a|a.category_id.to_i}
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    # @archetypes = Archetype.all.includes(:category).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    # @pages = (Archetype.count/pagesize).ceil
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

  get :stock do
    # OrderJobs.stock_job(force: true)
    @title = "Stock"
    @day = Date.parse(params[:day]) rescue Date.today
    @holders = {}
    @destocks = {}
    ksm_arch = KSM::Archetype.all
    ar_hash = ksm_arch.map(&:id)
    ar_hash.each do |sk|
      @holders[sk] ||= {}
      @destocks[sk] ||= {}
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
  
  post :list, :provides => :json do
    @archs = KSM::Archetype.all
    cat = params[:cat].to_i
    products = @archs.select{|a|a.category_id == cat}.map(&:to_r)
    products.to_json
  end
end