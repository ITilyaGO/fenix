Fenix::App.controllers :archetypes do
  get :oindex do
    @title = "Archetypes"
    @cats = KSM::Category.toplevel
    @archetypes = KSM::Archetype.all
    @categories = KSM::Category.all
    @kc_archs = CabiePio.folder(:product, :archetype).flat
    @archs = KSM::Archetype.all
    @grouped = @archs.group_by{|a|a.category_id}
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @r = url(:archetypes, :index)
    render 'archetypes/index'
  end

  get :products do
    @title = "Archetypes"
    @cats = KSM::Category.toplevel
    @archetypes = KSM::Archetype.all.map{|a|[a.id, a]}.to_h
    @categories = KSM::Category.all
    @kc_archs = CabiePio.folder(:product, :archetype).flat
    @kc_multi = CabiePio.folder(:product, :archetype_multi).flat.trans(nil, :to_i)
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    # @archetypes = Archetype.all.includes(:category).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    # @pages = (Archetype.count/pagesize).ceil
    render 'archetypes/products'
  end
  
  get :index do
    @title = t 'tit.archetypes.list'
    @arch = KSM::Archetype.new(id: -1)
    @cats = KSM::Category.toplevel
    @categories = KSM::Category.all
    
    render 'archetypes/listform'
  end

  get :e, :with => :id do
    @title = t 'tit.archetypes.list'
    @arch = KSM::Archetype.find(params[:id])
    @cats = KSM::Category.toplevel
    @categories = KSM::Category.all
    @squadconf = @arch.serializable_hash

    render 'archetypes/listform'
  end

  put :updatex, :with => :id do
  end

  get :new do
    @title = "New archetype"
    @archetype = KSM::Archetype.nest
    @archetype.save
    @cats = KSM::Category.toplevel
    render 'archetypes/edit'
  end
  
  put :update, :with => :id do
    @title = pat(:update_title, :model => "product #{params[:id]}")
    @archetype = KSM::Archetype.find(params[:id])
    if @archetype.exist?
      @archetype.name = params[:ksm_archetype][:name]
      @archetype.category_id = params[:ksm_archetype][:category_id]
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
    @cats = KSM::Category.toplevel
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
    @grouped = @archs.group_by(&:category_id)
    @cats = KSM::Category.toplevel
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
    @arch = KSM::Archetype.find params[:id]
    @olneed = KSM::OrderNeed.query("#{@arch.id}_", type: :prefix).flatless
    @need = Stock.need @arch.id
    @stock = Stock.free @arch.id
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
    stockdays = Stock::In.find_all(dids).flatless
    destockdays = Stock::Out.find_all(dids).flatless

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
    @day = Date.parse params[:segment].split(',').last rescue Date.today
    @holders = {}
    @destocks = {}
    @olneed = {}
    ksm_arch = KSM::Archetype.all.select { |a| a.category_id == params[:cat] }
    ksm_arch = KSM::Archetype.all if params[:all] or !params[:cat]
    @openstack = []
    if cat = params[:cat]
      @openstack << cat
      ksmc = KSM::Category.find cat
      @openstack << ksmc.category.id
      @openstack << ksmc.category.section.id
    end
    @squadconf = { openstack: @openstack }
    ar_hash = ksm_arch.map(&:id)
    ar_hash.each do |sk|
      @holders[sk] ||= {}
      @destocks[sk] ||= {}
      @olneed[sk] = KSM::OrderNeed.query("#{sk}_", type: :prefix).flatless.values.sum
    end
    7.times do |i|
      dt = (@day-i).strftime('%y%m%d')
      all_ids = ar_hash.map{|p|archetype_daystock(p, @day-i)}
      stockday = Stock::In.find_all(all_ids).flatless
      stockday.each do |sk, sv|
        ap = sk.split('_').first
        @holders[ap] ||= {}
        @holders[ap][@day-i] = sv
      end
      destockday = Stock::Out.find_all(all_ids).flatless
      destockday.each do |sk, sv|
        ap = sk.split('_').first
        @destocks[ap] ||= {}
        @destocks[ap][@day-i] = sv
      end
    end

    @cats = KSM::Category.all.select{|c| c.category_id.nil?}.sort_by(&:sn)
    @cat = cat
    @categories = KSM::Category.all
    @ar_grouped = ksm_arch.group_by(&:category_id)
    arp = CabiePio.folder(:product, :archetype).flat
    @kc_stocks = Stock.free.flatless
    @kc_needs = Stock.need.flatless

    if params[:start] or params[:segment]
      start_from = timeline_unf(params[:start]) rescue Date.today
      @prev = start_from
      @next = @prev + 6
      params[:segment] = nil if params[:segment]&.empty?
      segment = params[:segment].split(',') if params[:segment]
      @prev = timeline_unf segment.first if segment
      @next = timeline_unf segment.last if segment
      @orneed = @prev.step(@next).map do |day|
        CabiePio.query("p/anewdate/order>#{timeline_id day}_", type: :prefix).flat.trans(nil, :to_i).values
      end.flatten.uniq
      arches = Stock::Linkage.all.flatless
      parchs = @orneed.map do |oid|
        order = Order.find oid
        order.order_lines.map{|l|archetype_order(arches[l.product_id], l.id, order.id)}
      end.flatten
      olneeda = KSM::OrderNeed.find_all(parchs).group_by { |kon| kon.splitted[:arch] }
      @olneed = olneeda.map { |p,ary| [p, ary.sum(&:body)] }.to_h
    end

    # catgroup = products_hash.keys.group_by{|k|products_hash[k]}
    # @catstock = catgroup.map{|k,v|[k, v.map{|p|@kc_stocks.fetch(arp[p], 0)}.size{|x|x<0?x:0}]}.to_h
    # @catneed = catgroup.map{|k,v|[k, v.map{|p|@kc_needs.fetch(arp[p], 0)}.size{|x|x>0?x:0}]}.to_h
    @catneed = @catstock = { params[:cat] => 1 }
    @kc_archs = arp

    # @products = Product.all
    # @kc_index = arp.map{|p, a| [a, @products.detect{|i|i.id == p}&.sn || 0]}.to_h
    @cattree = otree_cats3 cats_olist

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

        prev_day = Stock::In.find id, day
        prev_day.save stock_in.to_i

        stock = Stock::Free.find id
        stock.diff prev_day.gap
      end
    end

    redirect url(:archetypes, :stock, cat: params[:cat], segment: params[:segment])
  end
  
  # Obsolete
  get :stock_clean do
    ol_need = CabiePio.folder(:need, :order).flat
    oids = ol_need.keys.map{|r|r.split('_').last}.uniq
    os = oids.map{|id|KSM::OrderStatus.find(id)}
      .select{|o|!o.exist?||o.what?(:finished)||o.what?(:shipped)||o.what?(:canceled)||o.what?(:draft)}
    
    @os = os
    render 'archetypes/stock_clean'
  end
  
  # Obsolete
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
    cat = params[:cat]
    products = @archs.select{|a|a.category_id == cat}.map(&:to_r)
    products.to_json
  end

  post :list_by_filters, :provides => :json do
    cat = empty_to_nil params[:cat]
    cat = nil if cat == 'all'
    search = empty_to_nil params[:search]

    archs = KSM::Archetype.all
    archs.select!{ |a| a.category_id == cat } if cat

    if search
      search_list = search.downcase.split(/[\s,.'"()-]/).compact
      archs.select! do |p|
        pdn_d = p.name.downcase
        search_list.all?{ |w| pdn_d.include?(w) }
      end
    end
    archs.sort_by!(&:name)
    data = archs.map do |a|
      {
        id: a.id,
        name: a.name,
        c_at: a.created_at.strftime('%d.%m.%y %H:%M'),
        category_id: a.category_id,
        g: a.g ? 1 : 0,
      }
    end

    data.to_json
  end

  put :bbtie, :provides => :json do
    arch = KSM::Archetype.find params[:left]
    return {}.to_json unless arch.exist?
    arch.bbid = params[:right]
    arch.save
    {}.to_json
  end

  get :reserve do
    @title = "Timeline"
    @print_btn = 1
    start_from = timeline_unf(params[:start]) rescue Date.today
    @prev = start_from.beginning_of_week + Date::BOW
    @next = @prev.next_week
    @weeks = []
    8.times do |i|
      @weeks << { :date => (pr = @prev + (i -2)*7), :end => pr.next_week }
    end
    @orneed = @prev.step(@next).map do |day|
      CabiePio.query("p/anewdate/order>#{timeline_id day}_", type: :prefix).flat.trans(nil, :to_i).values
    end.flatten.uniq
    @orders = Order.where(id: @orneed)

    arches = CabiePio.folder(:product, :archetype).flat
    parchs = @orneed.map do |oid|
      order = Order.find oid
      order.order_lines.map{|l|archetype_order(arches[l.product_id], l.id, order.id)}
    end.flatten
    @rese = CabiePio.all_keys(parchs, folder: [:need, :order]).flat.map{|k,v|[k.split('_')[1].to_i, v.to_i]}.to_h
    @olneed = CabiePio.all_keys(parchs, folder: [:need, :order]).flat.trans(nil, :to_i)
    @kc_status = {}
    @kc_orders = {}
    @kc_towns = {}
    @kc_timelines = {}
    # @olneed = @orneed.map do |order|
    #   CabiePio.query("p/need/order>*._#{order}", type: :regex).flat.trans(nil, :to_i)
    # end.flatten

    render 'archetypes/reserve'
  end

  get :multiedit do
    @title = "Мультиредактор заготовок"
    @cats = KSM::Category.toplevel.sort_by(&:wfindex)
    @fields = { name: 'Название', category_id: 'Категория', g: 'Группа' }

    render 'archetypes/multiedit'
  end

  post :multiedit_save do
    content_type 'text/event-stream'
    stream :keep_open do |out|
      begin
        data = JSON.parse(params[:data])
        archs = KSM::Archetype.find_all(data.keys)
        cats_ids = KSM::Category.toplevel.map(&:subcategories).flatten.map(&:id)
        prew_time_now = Time.now.to_f
        
        other_keys = ['g', 'category_id']
        value_guard = {
          'name' => :to_s,
        }

        archs_count = archs.size
        out << "§MPROD:#{ archs_count.to_s }"

        archs.each_with_index do |arch, p_index|
          begin
            line = data[arch.id]

            group = empty_to_nil(line['g'])&.to_i
            category_id = empty_to_nil(line['category_id'])&.to_s

            other_keys.each{ |k| line.delete(k) }
            line.each do |k, v|
              next if v.empty?
              v = v&.strip.send(value_guard[k])
              next if arch.send("#{ k }") == v
              arch.send("#{ k }=", v)
            end

            arch.g = group == 1 if group

            if (cats_ids.include?(category_id))
              arch.category_id = category_id
            else
              raise 'Категория с таким ID не найдена'
            end if category_id

            if arch.save
              flash[:success] = pat(:create_success, :model => 'archetype')
            else
              flash.now[:error] = pat(:create_error, :model => 'archetype')
            end

            time_now = Time.now.to_f
            if (time_now - prew_time_now > 2)
              prew_time_now = time_now
              out << "§#{ p_index }"
            end
          rescue Exception => e
            out << "§MERRP:ID:[#{ arch.id }] - Error: #{ e }"
          end
        end
      rescue Exception => e
        out << "§MERR:#{ e.inspect }"
      end
    end
  end
end