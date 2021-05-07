Fenix::App.controllers :orders do
  get :index do
    @title = "Все текущие рабочие заказы"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"
    orders_query = Order.where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished])
    orders_query = orders_query.where(delivery: params[:deli].to_i) if params[:deli]
    @orders = orders_query.includes(:client, :place, :order_parts, :timeline).order(sort => dir)
    if current_account.limited_orders?
      @filtered_by_user = OrderPart.where(:order_id => orders_query.ids, :section => current_account.section_id).pluck(:order_id)
    end
    @pages = (orders_query.count/pagesize).ceil
    @sections = Section.includes(:categories).all
    a_managers(@orders.map(&:id), @orders.map(&:client_id))
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    @r = url(:orders, :index)
    render 'orders/index'
  end

  get :draft do
    @title = "Непроверенные заказы"
    @orders = Order.all
      .includes(:client, :place, :order_parts)
      .where("status = ?", Order.statuses[:draft]).order(:updated_at => :desc)
    @sections = Section.includes(:categories).all
    a_towns(@orders.map(&:id), @orders.map(&:client_id))
    @r = url(:orders, :index)
    render 'orders/draft'
  end

  get :finished do
    @title = "Собранные заказы"
    @print_btn = 1
    @orders = Order.all
      .includes(:client, :place, :order_parts)
      .preload(:client => :place)
      .where("status = ?", Order.statuses[:finished]).order(:updated_at => :desc)
    @old = params[:old].present?
    if !@old
      @orders = @orders.where('updated_at > ?', Date.today - 1.month)
    else
      pagesize = PAGESIZE
      @page = !params[:page].nil? ? params[:page].to_i : 1
      @pages = (@orders.count/pagesize).ceil
      @orders = @orders.offset((@page-1)*pagesize).take(pagesize)
      @r = url(:orders, :finished, :old => 1)
    end
    @sections = Section.all
    a_towns(@orders.map(&:id), @orders.map(&:client_id))
    render 'orders/finished'
  end

  get :archive do
    @title = "Отправленные заказы в архиве"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"
    @orders = Order.where("status >= ?", Order.statuses[:shipped]).order(sort => dir).offset((@page-1)*pagesize).take(pagesize)
    @pages = (Order.where("status >= ?", Order.statuses[:shipped]).count/pagesize).ceil
    @sections = Section.includes(:categories).all
    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)
    @r = url(:orders, :archive)
    render 'orders/archive'
  end

  get :by_manager, :with => :id do
    @manager = Manager.find(params[:id])
    places = Place.where(region_id: @manager.region_ids).pluck(:id)
    @title = "Все текущие заказы #{@manager.name}"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"

    @sections = Section.includes(:categories).all
    @kc_orders = CabiePio.folder(:orders, :towns).flat
    @kc_delivery = CabiePio.folder(:orders, :delivery_towns).flat
    @kc_hometowns = CabiePio.folder(:clients, :hometowns).flat
    @kc_client_delivery = CabiePio.folder(:clients, :delivery_towns).flat
    codes = @kc_orders.values.uniq + @kc_delivery.values.uniq + @kc_client_delivery.values.uniq + @kc_hometowns.values.uniq
    @kc_towns = KatoAPI.batch(codes)
    kc_town_managers = CabiePio.folder(:towns, :managers).flat
    @kc_managers = codes.map do |code|
      hier = Kato::Hier.for(code).codes
      manager = hier.detect{|c| kc_town_managers[c]}
      [code, kc_town_managers[manager]]
    end.to_h.compact
    @managers = Manager.all.pluck(:id, :name).to_h
    manager_places = @kc_managers.to_a.group_by(&:last).transform_values{|v|v.flat_map(&:first)}[@manager.id.to_s] || []
    # search_orders = @kc_orders.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    search_clients = @kc_hometowns.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    @orders = Order.includes(:client, :place, :order_parts, :timeline)
      .where(client_id:search_clients)
      .where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished])
      .order(sort => dir)
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    render 'orders/index'
  end

  get :no_manager do
    @title = "Все текущие заказы без менеджера"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"

    @sections = Section.includes(:categories).all
    @kc_orders = CabiePio.folder(:orders, :towns).flat
    @kc_delivery = CabiePio.folder(:orders, :delivery_towns).flat
    @kc_hometowns = CabiePio.folder(:clients, :hometowns).flat
    @kc_client_delivery = CabiePio.folder(:clients, :delivery_towns).flat
    codes = @kc_orders.values.uniq + @kc_delivery.values.uniq + @kc_client_delivery.values.uniq + @kc_hometowns.values.uniq
    @kc_towns = KatoAPI.batch(codes)
    kc_town_managers = CabiePio.folder(:towns, :managers).flat
    @kc_managers = codes.map do |code|
      hier = Kato::Hier.for(code).codes
      manager = hier.detect{|c| kc_town_managers[c]}
      [code, kc_town_managers[manager]]
    end.to_h.compact
    @managers = Manager.all.pluck(:id, :name).to_h
    manager_places = @kc_managers.to_a.group_by(&:last).transform_values{|v|v.flat_map(&:first)}.values.flatten
    # search_orders = @kc_orders.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    search_clients = @kc_hometowns.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    @orders = Order.includes(:client, :place, :order_parts, :timeline)
      .where.not(client_id:search_clients)
      .where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished])
      .order(sort => dir)
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    render 'orders/index'
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.includes(:order_lines).find(params[:id])
    @sections = Section.includes(:categories).all
    @my_section = current_account.section
    @order_part = @order.order_parts.find_by(:section_id => @my_section)
    @tabs = Category.where(:category => nil)

    @kc_client_hometown = CabiePio.get([:clients, :hometowns], @order.client.id).data
    @kc_client_delivery = CabiePio.get([:clients, :delivery_towns], @order.client.id).data
    @kc_order_town = CabiePio.get([:orders, :towns], @order.id).data
    @kc_order_delivery = CabiePio.get([:orders, :delivery_towns], @order.id).data
    @kc_towns = KatoAPI.batch([@kc_client_hometown, @kc_client_delivery, @kc_order_town, @kc_order_delivery].compact)

    kc_town_managers = CabiePio.folder(:towns, :managers).flat
    hier = Kato::Hier.for(@kc_client_hometown).codes
    manager = kc_town_managers.fetch(hier.detect{|c| kc_town_managers[c]}, 0)
    @manager = Manager.find(manager) rescue nil
    @timeline_at = CabiePio.get([:orders, :timeline], @order.id).data
    @timeline_date = timeline_unf(@timeline_at) unless @timeline_at.nil?

    calendar_init(Date.today)

    if @order
      @order.actualize
      render 'orders/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  # get :edit, :with => :id do
  #   @title = pat(:edit_title, :model => "order #{params[:id]}")
  #   @order = Order.includes(:order_lines).find(params[:id])
  #   @cats = Category.where(:category_id => nil)
  #   if @order
  #     render 'orders/edit'
  #   else
  #     flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
  #     halt 404
  #   end
  # end

  get :show, :with => :id do
    @title = "Viewing order #{params[:id]}"
    @order = Order.includes(:order_lines).find(params[:id])
    @sections = Section.includes(:categories).all
    @my_section = current_account.section
    @order_part = @order.order_parts.find_by(:section_id => @my_section)
    @tabs = Category.where(:category => nil)

    @kc_client_hometown = CabiePio.get([:clients, :hometowns], @order.client.id).data
    @kc_client_delivery = CabiePio.get([:clients, :delivery_towns], @order.client.id).data
    @kc_order_town = CabiePio.get([:orders, :towns], @order.id).data
    @kc_order_delivery = CabiePio.get([:orders, :delivery_towns], @order.id).data
    @kc_towns = KatoAPI.batch([@kc_client_hometown, @kc_client_delivery, @kc_order_town, @kc_order_delivery].compact)

    if @order
      render 'orders/show'
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  get :new, :with => :id do
    @title = "New order"
    @online = Online::Order.includes(:order_lines).find(params[:id])
    a = @online.account
    @client = Client.find_by(online_id: @online.account_id)
    @kc_online_town = KyotoCorp::Online.get([:accounts, :places], @online.account_id).data
    if !@client
      ct = Client.arel_table
      pt = Place.arel_table
      place = Place.where(pt[:name].matches(a.city)).first
      @clients = Client.includes(:place).where(ct[:email].matches(a.email).or(ct[:place_id].matches(place.id))) rescue []
      @clients = Client.all if !@clients.any?
    end
    start_from = Date.today
    ky_month_1 = start_from.strftime('%y%m')
    ky_month_2 = start_from.next_month.strftime('%y%m')
    @ktm = CabiePio.all([:timeline, :order], [ky_month_1]).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], [ky_month_2]).flat
    @ctm = calendar_group(@ktm)
    render 'orders/new'
  end

  post :create do
    # @order = Order.new(params[:order])
    # cats = Category.where(:category => nil)
    # where(:category => nil)@tabs.each do |tab|
    params[:order][:delivery] = params[:order][:delivery].to_i
    create_new = params[:order]["create"] == "true"
    sync_only_id = params[:order]["sync_id"] == "true"
    sync_city = params[:order]["sync_city"] == "true"

    client = params[:order]["client_id"]
    online = Online::Order.includes(:order_lines, :account).find(params[:id])
    if sync_only_id
      sync_client = Client.find(client)
      sync_client.online_id = online.account.id
      sync_client.save
    end
    if create_new
      city = sync_city ? Place.find(params[:order]["place_id"]) : Place.where(:name => online.account.city).first
      dup = {:online_id => online.account.id, :name => online.account.name, :tel => online.account.tel, :place => city, :email => online.account.email, :org => online.account.org}
      dup[:online_place] = online.account.city if city.nil?
      new_client = Client.create(dup)
      client = new_client.id
    end

    # order = online.attributes.merge({:online_id => online.id, :status => :anew, :client_id => params[:order][:client_id]})
    # h = Order.new
    # h.attributes.merge(order.slice(*h.attributes))
    # order = order.slice([:account_id])
    # order.delete(:account_id)
    # h.save
    order = Order.new({:online_id => online.id, :status => :draft, :client_id => client, :online_at => online.created_at, :description => online.description, :total => online.total})
    order.id = params[:order]["id"] if !params[:order]["id"].blank?
    order.created_at = order.online_at
    order.place_id = params[:order]["place_id"]
    order.priority = params[:order][:priority] == "true"
    order.delivery = params[:order][:delivery].to_i
    online.order_lines.each do |line|
      ol = OrderLine.new(product_id: line.product_id, description: line.description, amount: line.amount, price: line.amount > 0 ? line.sum/line.amount : 0)
      order.order_lines << ol
    end
    order.save

    sections = Section.all
    sections.each do |s|
      include_section = false
      s.categories.each do |c|
        include_section = order.by_cat?(c.id)
        break if include_section
      end
      if include_section
        op = OrderPart.new(:section_id => s.id, :state => :anew)
        order.order_parts << op
      end
    end
    order.all_parts = order.order_parts.size if order.order_parts.any?
    order.save
    order.actualize
    calc_complexity_for order

    delivery_at = params[:cabie][:timeline_at]
    if timeline_date = Date.parse(delivery_at) rescue nil
      CabiePio.set [:timeline, :order], timeline_order(order.id, timeline_date), order.id
      CabiePio.set [:orders, :timeline], order.id, timeline_id(timeline_date)
    end
    code = params[:cabie][:kato_place]
    if Kato.valid? code
      CabiePio.set [:orders, :towns], order.id, code
    end

    redirect(url(:orders, :draft))
    # if @order.save
    #   @title = pat(:create_title, :model => "order #{@order.id}")
    #   flash[:success] = pat(:create_success, :model => 'Order')
    #   params[:save_and_continue] ? redirect(url(:orders, :index)) : redirect(url(:orders, :edit, :id => @order.id))
    # else
    #   @title = pat(:create_title, :model => 'order')
    #   flash.now[:error] = pat(:create_error, :model => 'order')
    #   render 'orders/new'
    # end
  end

  get :empty do
    @title = "New order"
    @order_lines = []
    render 'orders/empty'
  end

  post :empty do
    # @order = Order.new(params[:order])
    # cats = Category.where(:category => nil)
    # where(:category => nil)@tabs.each do |tab|

    # online = Online::Order.includes(:order_lines).find(params[:id])
    # order = online.attributes.merge({:online_id => online.id, :status => :anew, :client_id => params[:order][:client_id]})
    # h = Order.new
    # h.attributes.merge(order.slice(*h.attributes))
    # order = order.slice([:account_id])
    # order.delete(:account_id)
    # h.save
    params[:order][:delivery] = params[:order][:delivery].to_i
    order = Order.new(params[:order])
    order.id = params[:order]["id"] if !params[:order]["id"].blank?
    order.status = :draft

    # order = order.attributes.merge({ :status => :anew, :online_at => order.created_at })
    # order = Order.new({:online_id => online.id, :status => :anew, :client_id => client, :online_at => online.created_at, :description => online.description, :total => online.total})
    params[:line].each do |line|
      # l = line
      # l = line.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      # break if l[:id].blank?
      # i = l['id']
      # break if i.to_i == 0
      next if line['amount'].blank? || line['amount'] == 0
      p = Product.find(line['id']) rescue nil
      next if !p
      ol = OrderLine.new({ :product_id => p.id, :amount => line['amount'], :price => p.price, :description => line['comment'] })
      order.total += p.price*ol.amount
      order.order_lines << ol
      # ol.update_attributes(l)
    end
    order.save

    sections = Section.all
    sections.each do |s|
      include_section = false
      s.categories.each do |c|
        include_section = order.by_cat?(c.id)
        break if include_section
      end
      if include_section
        op = OrderPart.new(:section_id => s.id, :state => :anew)
        order.order_parts << op
      end
    end
    order.all_parts = order.order_parts.size if order.order_parts.any?
    order.save
    order.actualize
    calc_complexity_for order

    delivery_at = params[:cabie][:timeline_at]
    if timeline_date = Date.parse(delivery_at) rescue nil
      CabiePio.set [:timeline, :order], timeline_order(order.id, timeline_date), order.id
      CabiePio.set [:orders, :timeline], order.id, timeline_id(timeline_date)
    end
    code = params[:cabie][:kato_place]
    if Kato.valid? code
      CabiePio.set [:orders, :towns], order.id, code
    end
    redirect(url(:orders, :draft))
  end

  get :fullempty do
    @title = "New order"
    @cats = Category.where(category: nil).order(:index => :asc)
    @parents = Product.pluck(:parent_id).compact.uniq
    calendar_init
    render 'orders/fullempty'
  end

  get :copy, :with => :id do
    @title = "Copy order #{params[:id]}"
    order = Order.find(params[:id])
    @order_lines = order.order_lines
    @total = order.total
    @order_client = order.client
    @kc_town = CabiePio.get([:orders, :towns], order.id).data
    @kc_timeline = CabiePio.get([:orders, :timeline], order.id).data
    @form = order
    @force_timeline = true
    calendar_init
    render 'orders/empty'
  end

  get :addition, :with => :id do
    @title = "Create additional order for #{params[:id]}"
    order = Order.find(params[:id])
    @order_lines = []
    order.order_lines.each do |ol|
      next if (ol.done_amount || 0) >= ol.amount
      ol.amount -= ol.done_amount || 0
      @order_lines << ol
    end
    @order_client = order.client
    @order_place = order.place
    @descr = order.description
    order.order_lines = @order_lines
    @total = order.total_price
    @kc_town = CabiePio.get([:orders, :towns], order.id).data
    @kc_timeline = CabiePio.get([:orders, :timeline], order.id).data
    @form = order
    @force_timeline = true
    calendar_init
    render 'orders/empty'
  end

  get :correct, :with => :id do
    @title = "Edit order #{params[:id]}"
    order = Order.find(params[:id])
    @order_lines = order.order_lines
    @total = order.total
    @id = order.id
    @order_client = order.client
    @order_place = order.place
    @descr = order.description
    @form = order
    @kc_town = CabiePio.get([:orders, :towns], order.id).data
    render 'orders/empty'
  end

  post :save, :with => :id do
    order = Order.find(params[:id])
    order.status = :draft
    order.delivery = params[:order][:delivery].to_i
    order.priority = params[:order][:priority] == 'true'
    order.description = params[:order][:description]
    order.client_id = params[:order]["client_id"]
    order.place_id = params[:order]["place_id"]
    order.done_parts = 0
    order.total = 0
    order.done_total = 0

    # order = order.attributes.merge({ :status => :anew, :online_at => order.created_at })
    # order = Order.new({:online_id => online.id, :status => :anew, :client_id => client, :online_at => online.created_at, :description => online.description, :total => online.total})
    order.order_lines.destroy_all
    params[:line].each do |line|
      p = Product.find(line['id']) rescue nil
      next if !p
      ol = OrderLine.new({ :product_id => p.id, :amount => line['amount'], :price => p.price, :description => line['comment'] })
      order.total += p.price*ol.amount
      order.order_lines << ol
      # ol.update_attributes(l)
    end
    order.save

    order.order_parts.destroy_all
    sections = Section.all
    sections.each do |s|
      include_section = false
      s.categories.each do |c|
        include_section = order.by_cat?(c.id)
        break if include_section
      end
      if include_section
        op = OrderPart.new(:section_id => s.id, :state => :anew)
        order.order_parts << op
      end
    end
    order.all_parts = order.order_parts.size if order.order_parts.any?
    order.save
    order.actualize
    calc_complexity_for order
    
    code = params[:cabie][:kato_place]
    if Kato.valid? code
      CabiePio.set [:orders, :towns], order.id, code
    end
    redirect(url(:orders, :draft))
  end

  get :anew, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    if @order.draft?
      @order.status = :anew
      @order.save
      redirect(url(:orders, :draft))
    end
    redirect(url(:orders, :draft))
  end

  get :ship, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    if @order.finished?
      @order.track = "VO34888864"
      @order.status = :shipped
      @order.save
      flash[:success] = 'Заказ отправлен и у него есть номер накладной'
      redirect(url(:orders, :finished))
    end
    redirect(url(:orders, :finished))
  end

  get :status, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    @my_section = current_account.section
    @order_part = @order.order_parts.find_by(:section_id => @my_section)
    if @order_part.anew?
      @order_part.state = :current if @order_part.anew?
      @order_part.save
      @order.status = :current
      @order.save
    end
    redirect(url(:orders, :edit, :id => @order.id))
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    @order_part = @order.order_parts.find_by(:section_id => current_account.section)
    # @order.status = params[:status]
    @order.priority = params[:priority] == "true"
    delivery_at = params[:cabie][:timeline_at] rescue nil
    if timeline_date = Date.parse(delivery_at) rescue nil
      CabiePio.set [:timeline, :order], timeline_order(@order.id, timeline_date), @order.id
      CabiePio.set [:orders, :timeline], @order.id, timeline_id(timeline_date)
    end

    if @order_part and params[:order_part]
      # @order_part.status = params[:order_part]['done'] ? :finished : :current
      no_boxes = params[:order_part][:no_boxes] == '1'
      @order_part.boxes = params[:order_part][:boxes] || 0
      @order_part.boxes = 0 if no_boxes
      @order_part.transfer = params[:order_part][:transfer] || false
      @order_part.state = :finished if params[:next_status]
      @order_part.save
      # @order_part.update_attributes(params[:order_part])
    end
    if params[:next_status_all]
      @order.order_parts.each do |part|
        part.state = :finished
        part.save
      end
    end

    # @d1 = params[:line].first
    # render 'home/index'
    params[:line].each do |line|
      l = line.second
      # l = line.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      # break if l[:id].blank?
      i = l['id']
      break if !i
      ol = @order.order_lines.find(i)
      l['done_amount'] = l['done_amount'].to_i rescue 0
      ol.update_attributes(l)
    end
    @order.done_parts = @order.order_parts.where("state = ?", OrderPart.states[:finished]).size
    if @order.done_parts == @order.all_parts
      # don't need to use params here
      @order.status = :finished if !params[:save_finish]
      amount = 0.0
      @order.order_lines.each do |ol|
        next if ol.ignored
        amount += ol.price*(ol.done_amount || 0)
      end
      @order.done_total = amount
    end
    @order.save
    @order.actualize
    calc_complexity_for @order

    if @order.finished?
      redirect(url(:orders, :invoice, :id => @order.id))
    else
      redirect(url(:orders, :index))
    end
    # if @order.save
    #   redirect(url(:orders, :index))
    # else
    #   @title = pat(:create_title, :model => 'order_part')
    #   flash.now[:error] = pat(:create_error, :model => 'order_part')
    #   render 'orders/save'
    # end

    # if @order
    #   if @order.update_attributes(params[:order])
    #     flash[:success] = pat(:update_success, :model => 'Order', :id =>  "#{params[:id]}")
    #     params[:save_and_continue] ?
    #       redirect(url(:orders, :index)) :
    #       redirect(url(:orders, :edit, :id => @order.id))
    #   else
    #     flash.now[:error] = pat(:update_error, :model => 'order')
    #     render 'orders/edit'
    #   end
    # else
    #   flash[:warning] = pat(:update_warning, :model => 'order', :id => "#{params[:id]}")
    #   halt 404
    # end
  end

  get :boxes, :with => :id do
    @title = pat(:set_boxes, :model => "order #{params[:id]}")
    @order = Order.includes(:order_parts).find(params[:id])

    if Order.statuses[@order.status] < Order.statuses[:shipped]
      render 'orders/boxes'
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :boxes, :with => :id do
    @title = pat(:update_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])

    params[:line].each do |line|
      l = line.second
      i = l[:id]
      break if !i
      op = @order.order_parts.find(i)
      op.update_attributes(l)
    end

    @order.save

    redirect(url(:orders, :finished))
  end

  get :price, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.includes(:order_lines).find(params[:id])
    @sections = Section.includes(:categories).all
    @tabs = Category.where(:category => nil)

    if @order
      render 'orders/price'
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :price, :with => :id do
    @title = pat(:update_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])

    params[:line].each do |line|
      l = line.second
      i = l['id']
      break if !i
      ol = @order.order_lines.find(i)
      ol.update_attributes(l)
    end

    @order = Order.find(params[:id])
    amount = 0.0
    @order.order_lines.each do |ol|
      next if ol.ignored
      amount += ol.price*ol.done_amount
    end
    @order.done_total = amount
    @order.save

    redirect(url(:orders, :price, :id => params[:id]))
  end

  delete :destroy, :with => :id do
    # TODO: Delete order from tables
    @title = "Orders"
    order = Order.find(params[:id])
    if order && order.draft?
      if order.order_parts.destroy_all && order.order_lines.destroy_all && order.destroy
        flash[:success] = pat(:delete_success, :model => 'Order', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'order')
      end
      Timeline.destroy_all(:order_id => order.id)
      redirect url(:orders, :draft)
    else
      flash[:warning] = pat(:delete_warning, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Orders"
    unless params[:order_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'order')
      redirect(url(:orders, :index))
    end
    ids = params[:order_ids].split(',').map(&:strip)
    orders = Order.find(ids)

    if Order.destroy orders
      flash[:success] = pat(:destroy_many_success, :model => 'Orders', :ids => "#{ids.to_sentence}")
    end
    redirect url(:orders, :index)
  end

  get :torg12, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.includes(:order_lines).includes(order_lines: :product).find(params[:id])

    if @order
      render 'invoices/torg12', :layout => false
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  get :pdftorg12, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.includes(:order_lines).includes(order_lines: :product).find(params[:id])
    output = render 'invoices/torg12', :layout => false

    Princely.executable = settings.princebin
    princely = Princely::Pdf.new({ :path => settings.princepath, :log_file => settings.princelog })
    princely.add_style_sheets('./public/stylesheets/invoices.css')
    # princely.make_and_send_pdf "/orders/torg12/#{params[:id]}"

    content_type 'application/pdf'
    princely.pdf_from_string(output)
    # princely.pdf_from_string(File.read('form.html'))
    # @title = pat(:edit_title, :model => "order #{params[:id]}")
    # @order = Order.includes(:order_lines).includes(order_lines: :product).find(params[:id])
    # render :pdf, :template => "invoices/torg12", :layout => false
  end

  get :invoice, :with => :id do
    @order = params[:id]
    @pdfurl = url(:orders, :pdfnakl, :id => @order, :format => :pdf)
    render 'orders/framepdf'
  end

  get :nakl, :with => :id do
    @order = params[:id]
    render 'orders/gennakl'
  end

  get :pdfnakl, :with => :id, :provides => :pdf do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.includes(:order_lines).includes(order_lines: :product).find(params[:id])
    @account = params[:account]
    iso = CabiePio.get([:orders, :towns], @order.id).data
    @kc_town = KatoAPI.anything(iso)&.load.model.name || @order.place_name
    output = render 'invoices/nakl', :layout => false

    Princely.executable = settings.princebin
    princely = Princely::Pdf.new({ :path => settings.princepath, :log_file => settings.princelog })
    princely.add_style_sheets('./public/stylesheets/invoices.css')

    content_type 'application/pdf'
    princely.pdf_from_string(output)
  end

  post :products, :provides => :json do
    json_products_list
  end

  post :cities, :provides => :json do
    Place.select(:id, :name).to_json
  end

  post :cities3, :provides => :json do
    q = params[:q].force_encoding(Encoding::UTF_8)
    Place.where('umlike(lower(name), ?)', q).select(:id, :name).to_json
  end

  get :cities, :provides => :json do
    require 'benchmark'

    iterations = 1000

    a = Benchmark.bm do |bm|
      # joining an array of strings
      bm.report do
        arr = ["The", "current", "time", "is"]
        iterations.times do
          q = params[:q]
          r = Place.where('umlike(?, lower(name))', q).select(:id, :name).first(5).to_json
        end
      end
    end
    "2"

  end

  get :cities2, :provides => :json do
    q = params[:q]
    Client.all.to_json
    Place.where('like(?, lower(name))', q).select(:id, :name).first(10).to_json
    Place.where('umlike(?, lower(name))', q).select(:id, :name).first(10).to_json
  end

  post :clients2, :provides => :json do
    q = params[:q].gsub(/[^\wА-ЯЁа-яё -]/, '')[0..15]

    # Client.joins(:place).where('umlike(?, lower("clients"."name"))', q)
    # .where('umlike(?, lower("clients"."name")) OR umlike(?, lower("places"."name"))', q, q)
    # cts = Place.where('umlike(?, lower(name))', q).pluck(:id)
    res = []
    res << Client.joins(:place)
      .where('umlike(?, lower("clients"."name"))', q)
      .select("clients.id, clients.name, places.name as city").first(10)
    res << Client.joins(:place)
      .where('umlike(?, lower("places"."name"))', q)
      .select("clients.id, clients.name, places.name as city").first(20)
    res.flat_map(&:flatten).to_json
  end

  post :clients, :provides => :json do
    json_clients.to_json
    # Client.joins(:place).select(:id, :name, :org, :tel).to_json
  end
  # post :clients, :provides => :json do
  #   q = '%'+ params[:q] + '%'
  #   t = Client.arel_table
  #   # Client.select(:id, :name).to_json
  #   Client.where('lower(name) LIKE ?', params[:q]).select(:id, :name).to_json
  #   # .where(t[:city].matches(q).or(t[:tel].matches(q)).or(t[:email].matches(q))).select(:id, :name).to_json
  # end


  put :change_city, :with => :id do
    order = params[:id]
    town = params[:code]
    type = params[:type].to_sym.eql?(:delivery) ? :delivery_towns : :towns
    return { error: 'non-format' }.to_json unless Kato.valid? town
    exist = KatoAPI.anything town
    return { error: 'unknown' }.to_json if exist.blank?
    CabiePio.set [:orders, type], order, town
    { name: exist.model.name }.to_json
  end

  put :regroup do
    order_form = params[:order]
    order = Order.find(order_form[:id])
    order.delivery = order_form[:delivery].to_i
    order.save
    # true
  end
end
