Fenix::App.controllers :orders do
  get :index do
    @title = "Все текущие рабочие заказы"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"
    orders_query = Order.where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished])
    orders_query = orders_query.where(delivery: params[:deli].to_i) if params[:deli]
    @orders = orders_query.includes(:client).order(sort => dir)
    if current_account.limited_orders?
      @filtered_by_user = OrderPart.where(:order_id => orders_query.ids, :section => current_account.section_id).pluck(:order_id)
    end
    @pages = (orders_query.count/pagesize).ceil
    @sections = KSM::Section.all
    a_managers(@orders.map(&:id), @orders.map(&:client_id))
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    @kc_blinks = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline_blink]).flat.trans(:to_i)
    @kc_stickers = CabiePio.all_keys(@orders.map(&:id), folder: [:sticker, :order_progress]).flat.trans(:to_i, :to_f)
    @orders = @orders.sort_by{|o|@kc_timelines[o.id]||''} if params[:seq] == "timeline"
    @orders = @orders.sort_by{|o|@kc_towns[@kc_orders[o.id.to_s]]&.model&.name||''} if params[:seq] == "city"
    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i).reject{|k,v|v!='t'}
    @r = url(:orders, :index)
    @ra = [:orders, :index]
    @rah = { deli: params[:deli] } if params[:deli]
    render 'orders/index'
  end

  get :my do
    @manager = current_account
    @title = "Все текущие рабочие заказы"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"
    # @pages = (orders_query.count/pagesize).ceil
    @sections = KSM::Section.all
    # a_managers(@orders.map(&:id), @orders.map(&:client_id))
    the_managers
    # manager_places = @kc_managers.to_a.group_by(&:last).transform_values{|v|v.flat_map(&:first)}[@manager.id.to_s] || []
    # search_clients = @kc_hometowns.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    orders_base = Order.in_work.pluck(:client_id)
    search_clients = Client.where(id: orders_base, manager_id: @manager.id).pluck(:id)
    orders_query = Order
      .where(client_id: [nil] + search_clients)
      .where("status > ?", Order.statuses[:draft])
      .where("status < ?", Order.statuses[:finished])
    orders_query = orders_query.where(delivery: params[:deli].to_i) if params[:deli]
    @orders = orders_query.includes(:client).order(sort => dir)
    if current_account.limited_orders?
      @filtered_by_user = OrderPart.where(:order_id => orders_query.ids, :section => current_account.section_id).pluck(:order_id)
    end

    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    @kc_blinks = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline_blink]).flat.trans(:to_i)
    @kc_stickers = CabiePio.all_keys(@orders.map(&:id), folder: [:sticker, :order_progress]).flat.trans(:to_i, :to_f)
    @orders = @orders.sort_by{|o|@kc_timelines[o.id]||''} if params[:seq] == "timeline"
    @orders = @orders.sort_by{|o|@kc_towns[@kc_orders[o.id.to_s]]&.model&.name||''} if params[:seq] == "city"
    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i).reject{|k,v|v!='t'}
    @r = url(:orders, :index)
    @ra = [:orders, :my]
    @rah = { deli: params[:deli] } if params[:deli]
    render 'orders/index'
  end

  get :draft do
    @title = "Непроверенные заказы"
    @orders = Order.all
      .includes(:client, :place, :order_parts)
      .where("status = ?", Order.statuses[:draft]).order(:updated_at => :desc)
    @sections = KSM::Section.all
    a_towns(@orders.map(&:id), @orders.map(&:client_id))
    calendar_init
    @r = url(:orders, :draft)
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
      @r = url(:orders, :finished, :old => 1)
      @ra = [:orders, :finished]
    end
    if role_is? :manager
      orders_base = @orders.map(&:client_id)
      search_clients = Client.where(id: orders_base, manager_id: current_account.id).pluck(:id)
      @orders = @orders.where(client_id: [nil] + search_clients)
    end
    @orders = @orders.offset((@page-1)*pagesize).take(pagesize) if @old

    @sections = KSM::Section.all
    a_towns(@orders.map(&:id), @orders.map(&:client_id))
    @kc_done = CabiePio.all_keys(@orders.map(&:id), folder: [:stock, :order, :done]).flat.trans(:to_i)

    render 'orders/finished'
  end


  get :shipready do
    @title = "К отправке"
    # @print_btn = 1
    @orders = Order.all
      .includes(:client, :place, :order_parts)
      .preload(:client => :place)
      .where("status = ?", Order.statuses[:shipready]).order(:updated_at => :desc)
    # @old = params[:old].present?
    # if !@old
    #   @orders = @orders.where('updated_at > ?', Date.today - 1.month)
    # else
    #   pagesize = PAGESIZE
    #   @page = !params[:page].nil? ? params[:page].to_i : 1
    #   @pages = (@orders.count/pagesize).ceil
    #   @orders = @orders.offset((@page-1)*pagesize).take(pagesize)
    #   @r = url(:orders, :shipready, :old => 1)
    # end
    @sections = KSM::Section.all
    a_towns(@orders.map(&:id), @orders.map(&:client_id))
    @kc_done = CabiePio.all_keys(@orders.map(&:id), folder: [:stock, :order, :done]).flat.trans(:to_i)
    @transport = KSM::Transport.all

    render 'orders/shipready'
  end

  get :archive do
    @title = "Отправленные заказы в архиве"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"
    @orders = Order.where("status >= ?", Order.statuses[:shipped]).order(sort => dir).offset((@page-1)*pagesize).take(pagesize)
    @pages = (Order.where("status >= ?", Order.statuses[:shipped]).count/pagesize).ceil
    @sections = KSM::Section.all
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

    @sections = KSM::Section.all
    the_managers
    manager_places = @kc_managers.to_a.group_by(&:last).transform_values{|v|v.flat_map(&:first)}[@manager.id.to_s] || []
    # search_orders = @kc_orders.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    search_clients = @kc_hometowns.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    @orders = Order.includes(:client, :place, :order_parts, :timeline)
      .where(client_id: [nil] + search_clients)
      .where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished])
      .order(sort => dir)
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    @kc_stickers = CabiePio.all_keys(@orders.map(&:id), folder: [:sticker, :order_progress]).flat.trans(:to_i, :to_f)
    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i).reject{|k,v|v!='t'}
    @kc_blinks = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline_blink]).flat.trans(:to_i)
    render 'orders/index'
  end

  get :no_manager do
    @title = "Все текущие заказы без менеджера"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"

    @sections = KSM::Section.all
    the_managers
    manager_places = @kc_managers.to_a.group_by(&:last).transform_values{|v|v.flat_map(&:first)}.values.flatten
    # search_orders = @kc_orders.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    search_clients = @kc_hometowns.select{|k,v|manager_places.include? v}.keys.map(&:to_i)
    @orders = Order.includes(:client, :place, :order_parts, :timeline)
      .where.not(client_id: [nil] + search_clients)
      .where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished])
      .order(sort => dir)
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    @kc_stickers = CabiePio.all_keys(@orders.map(&:id), folder: [:sticker, :order_progress]).flat.trans(:to_i, :to_f)
    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i).reject{|k,v|v!='t'}
    @kc_blinks = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline_blink]).flat.trans(:to_i)
    render 'orders/index'
  end

  get :choosie, :with => :id do
    @order = params[:id]
    render 'orders/choosie'
  end

  get :preempty do
    @order = params[:id]
    @kc_towns = KatoAPI.batch([@kc_client_hometown, @kc_client_delivery, @kc_order_town, @kc_order_delivery].compact)
    render 'orders/preempty'
  end

  post :preempty do
    redirect url(:orders, :fullempty, place: params[:cabie][:kato_place])
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.includes(:order_lines_ar).find params[:id]
    # @order = Order.includes(:order_lines_ar).find(params[:id])
    @sections = KSM::Section.all
    # @sections = Section.includes(:categories).all
    # habits(@sections, :index)
    @my_section = @sections.detect{ |a| a.ix == current_account.section_id }
    @order_part = @order.order_parts.find_by(:section_id => @my_section&.ix)
    @tabs = Category.where(:category => nil)

    @kc_client_hometown = CabiePio.get([:clients, :hometowns], @order.client.id).data
    @kc_client_delivery = CabiePio.get([:clients, :delivery_towns], @order.client.id).data
    @kc_order_town = CabiePio.get([:orders, :towns], @order.id).data
    @kc_order_delivery = CabiePio.get([:orders, :delivery_towns], @order.id).data
    @kc_towns = KatoAPI.batch([@kc_client_hometown, @kc_client_delivery, @kc_order_town, @kc_order_delivery].compact)

    @stock_out = CabiePio.get([:stock, :order, :done], @order.id).data
    @olstickers = CabiePio.all_keys(@order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum]).flat
    kc_amt = CabiePio.get([:orders, :stickers_amount], @order.id).data.to_i
    @sticker_progress = sticker_order_progress(@order.id)
    @kc_products = CabiePio.folder(:products, :sticker).flat

    @timeline_at = CabiePio.get([:orders, :timeline], @order.id).data
    @timeline_blink = !CabiePio.get([:orders, :timeline_blink], @order.id).blank?
    @stickday_order = CabiePio.get([:orders, :stickday], @order.id).data
    @timeline_date = timeline_unf(@timeline_at) unless @timeline_at.nil?
    @stickday_date = timeline_unf(@stickday_order) unless @stickday_order.nil?
    @orderstatus = KSM::OrderStatus.find(@order.id)
    @order_ship = KSM::OrderShip.find(@order.id)
    
    calendar_init(Date.today)
    @ps = KSM::OrderImage.all_for(@order.id)

    arches = CabiePio.folder(:product, :archetype).flat
    parchs = @order.order_lines.map{|l|archetype_order(arches[l.product_id], l.id, @order.id)}
    @rese = CabiePio.all_keys(parchs, folder: [:need, :order]).flat.map{|k,v|[k.split('_')[1].to_i, v.to_i]}.to_h

    cash = CabiePio.get([:orders, :cash], @order.id).data
    @cash = cash == 't' ? 2 : 1 if cash
    if @order
      @order.actualize
      render 'orders/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  get :stickers, :with => :id do
    halt 404
  end

  get :infact, :with => :id do
    halt 404
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

  get :txtf, :with => :id, :provides => :txt do
    @order = Order.includes(:order_lines_ar).find(params[:id]) #_ar
    @kc_order_town = CabiePio.get([:orders, :towns], @order.id).data
    @kc_towns = KatoAPI.batch([@kc_order_town])
    @sections = KSM::Section.all #KSM
    @my_section = @sections.detect{ |a| a.id == current_account.section }&.ix

    text = "#{@order.id} #{@kc_towns[@kc_order_town].model.name}\n"
    text << "\n"

    @sections.sort_by(&:ix).each_with_index do |s, i|
      next if i > 1
      s.categories.sort_by(&:wfindex).each do |tab|
        @order.by_cat(tab.id).sort_by{|a|a.product.cindex}.each do |ol|
          text << "#{ol.product.displayname}_#{!ol.description&.blank? ? ol.description : ' '}_#{ol.amount}\n"
        end
      end
    end
    text
  end

  get :show, :with => :id do
    @title = "Viewing order #{params[:id]}"
    @order = Order.includes(:order_lines_ar).find(params[:id])
    @sections = KSM::Section.all
    @my_section = @sections.detect{ |a| a.id == current_account.section }&.ix
    @order_part = @order.order_parts.find_by(:section_id => @my_section)
    @tabs = Category.where(:category => nil)

    @kc_client_hometown = CabiePio.get([:clients, :hometowns], @order.client.id).data
    @kc_client_delivery = CabiePio.get([:clients, :delivery_towns], @order.client.id).data
    @kc_order_town = CabiePio.get([:orders, :towns], @order.id).data
    @kc_order_delivery = CabiePio.get([:orders, :delivery_towns], @order.id).data
    @kc_towns = KatoAPI.batch([@kc_client_hometown, @kc_client_delivery, @kc_order_town, @kc_order_delivery].compact)

    if @order
      @order.actualize
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
    if @client
      @kc_town = CabiePio.get([:clients, :hometowns], @client.id).data
      @kc_client_hometown = KatoAPI.anything(@kc_town)
    else
      @kc_town = @online.account.city[1..-1]
      @kc_client_hometown = KatoAPI.anything(@kc_town)
    end
    # @kc_online_town = KyotoCorp::Online.get([:accounts, :places], @online.account_id).data
    if !@client
      @sel_client = Client.find_by(email: a.email) || Client.find_by(name: a.name)
      # ct = Client.arel_table
      # pt = Place.arel_table
      # place = Place.where(pt[:name].matches(a.city)).first
      # @clients = Client.includes(:place).where(ct[:email].matches(a.email).or(ct[:place_id].matches(place.id))) rescue []
      # @clients = Client.all if !@clients.any?
    end
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
      dup = {:online_id => online.account.id, :name => online.account.name, :tel => online.account.tel, :email => online.account.email, :org => online.account.org}
      # dup[:online_place] = online.account.city if city.nil?
      new_client = Client.create(dup)
      client = new_client.id

      code = params[:cabie][:kato_place]
      if Kato.valid? code
        CabiePio.set [:clients, :hometowns], client, code
      end
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
      ol = OrderLine.new(product_id: line.product.pio_id, description: line.description, amount: line.amount, price: line.amount > 0 ? line.sum/line.amount : 0)
      order.order_lines_ar << ol
    end
    order.save
    # oids = []
    # plookup = KSM::Backmig.find(:product).contents
    # order.order_lines_ar.each do |line|
    #   ol = KSM::OrderLine.nest
    #   ol.fill({ :merge => true, :product_id => plookup[line.product_id], :order_id => order.id, :amount => line.amount, :price => line.price, :description => line.description })
    #   ol.save
    #   oids << ol.id
    # end

    o_status = KSM::OrderStatus.find(order.id)
    o_status.setg(:draft)
    sections = KSM::Section.all
    sections.each do |s|
      include_section = false
      s.categories.each do |c|
        include_section = order.by_cat?(c.id)
        break if include_section
      end
      if include_section
        op = OrderPart.new(:section_id => s.ix, :state => :anew)
        order.order_parts << op
        o_status.sets(s.ix, :anew)
      end
    end
    o_status.save
    order.all_parts = order.order_parts.size if order.order_parts.any?
    order.save
    order.actualize
    calc_complexity_for order

    cash = params[:order][:cash] == 'true' ? 't' : 'f'
    CabiePio.set [:orders, :cash], order.id, cash

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
    params[:order][:priority] = params[:order][:priority] == 'true'
    ar = params[:order].dup
    ar.delete(:cash)
    order = Order.new(ar)
    order.id = params[:order]["id"] if !params[:order]["id"].blank?
    order.status = :draft
    order.save

    # order = order.attributes.merge({ :status => :anew, :online_at => order.created_at })
    # order = Order.new({:online_id => online.id, :status => :anew, :client_id => client, :online_at => online.created_at, :description => online.description, :total => online.total})
    postlines = params[:line].reject{ |line| line['amount'].blank? || line['amount'] == '0' }
    params[:line].each do |line|
      # l = line
      # l = line.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      # break if l[:id].blank?
      # i = l['id']
      # break if i.to_i == 0
      next if line['amount'].blank? || line['amount'] == 0
      p = Product.find(line['id']) rescue nil
      next if !p
      next unless p.exist?
      olar = OrderLine.new({ :product_id => p.id, :amount => line['amount'], :price => p.price, :description => line['comment'] })
      order.total += p.price*olar.amount
      order.order_lines_ar << olar
      # ol.update_attributes(l)
    end
    order.save
    # oids = []
    # postlines.each do |line|
    #   p = Product.find(line['id'])
    #   next unless p.exist?
    #   ol = KSM::OrderLine.nest
    #   ol.fill({ :merge => true, :product_id => p.id, :order_id => order.id, :amount => line['amount'].to_i, :price => p.price, :description => line['comment'] })
    #   ol.save
    #   oids << ol.id
    # end

    o_status = KSM::OrderStatus.find(order.id)
    o_status.setg(:draft)
    sections = KSM::Section.all
    sections.each do |s|
      include_section = false
      s.categories.each do |c|
        include_section = order.by_cat?(c.id)
        break if include_section
      end
      if include_section
        op = OrderPart.new(:section_id => s.ix, :state => :anew)
        order.order_parts << op
        o_status.sets(s.ix, :anew)
      end
    end
    o_status.save

    params[:ship] ||= {}
    o_ship = KSM::OrderShip.find(order.id)
    o_ship.clear_formize params[:ship]
    o_ship.save

    order.all_parts = order.order_parts.size if order.order_parts.any?
    order.save
    order.actualize
    calc_complexity_for order

    code = params[:cabie][:kato_place]
    if Kato.valid? code
      CabiePio.set [:orders, :towns], order.id, code
    end
    cash = params[:order][:cash] == 'true' ? 't' : 'f'
    CabiePio.set [:orders, :cash], order.id, cash

    redirect url(:orders, :choosie, id: order.id)
  end

  get :fullempty do
    @title = "New order"
    @cats = KSM::Category.all.select{ |c| c.category_id.nil? }.sort_by(&:wfindex)
    # Padrino.cache['cats'] ||= cats
    # @cats = Padrino.cache['cats']
    @parents = Product.pluck(:parent_id).compact.uniq
    @cattree = otree_cats3 cats_olist
    # @protree = otree_cats3 pro_olist(params[:place])
    @arp = Stock::Linkage.all.flatless
    @kc_stocks = Stock.free.flatless
    @kc_needs = Stock.need.flatless
    @place = params[:place]
    @order_place = KatoAPI.anything(@place) if @place
    render 'orders/fullempty'
  end

  get :copy, :with => :id do
    @title = "Copy order #{params[:id]}"
    @cats = KSM::Category.all.select{ |c| c.category_id.nil? }.sort_by(&:wfindex)
    order = Order.find(params[:id])
    @order_lines = order.order_lines
    @total = order.total
    @order_client = order.client
    @kc_town = CabiePio.get([:orders, :towns], order.id).data
    @kc_timeline = CabiePio.get([:orders, :timeline], order.id).data
    place = CabiePio.get([:orders, :towns], order.id).data
    @order_place = KatoAPI.anything(place) if place
    @place = place
    @form = order
    @cattree = otree_cats3 cats_olist
    @protree = otree_rendered place
    @force_timeline = true
    render 'orders/empty'
  end

  get :addition, :with => :id do
    @title = "Create additional order for #{params[:id]}"
    @cats = KSM::Category.all.select{ |c| c.category_id.nil? }.sort_by(&:wfindex)
    order = Order.find(params[:id])
    @order_lines = []
    order.order_lines.each do |ol|
      next if (ol.done_amount || 0) >= ol.amount
      dol = ol.dup
      dol.id = nil
      dol.amount -= dol.done_amount || 0
      @order_lines << dol
    end
    @order_client = order.client
    @order_place = order.place
    @descr = order.description
    # order.order_lines = @order_lines
    @total = order.total_price
    @kc_town = CabiePio.get([:orders, :towns], order.id).data
    @kc_timeline = CabiePio.get([:orders, :timeline], order.id).data
    place = CabiePio.get([:orders, :towns], order.id).data
    @order_place = KatoAPI.anything(place) if place
    @place = place
    @form = order
    @cattree = otree_cats3 cats_olist
    @protree = otree_rendered place
    @force_timeline = true
    render 'orders/empty'
  end

  get :touch, :with => :id do
    @title = "Correct order #{params[:id]}"
    @cats = KSM::Category.all.select{ |c| c.category_id.nil? }.sort_by(&:wfindex)
    order = Order.find(params[:id])
    @order_lines = order.order_lines
    @total = order.total
    @id = order.id
    @order_client = order.client
    @order_ship = KSM::OrderShip.find order.id
    place = CabiePio.get([:orders, :towns], order.id).data
    @order_place = KatoAPI.anything(place) if place
    @place = place
    @descr = order.description
    @form = order
    @cash = CabiePio.get([:orders, :cash], order.id).data == 't'
    render 'orders/touch'
  end

  get :correct, :with => :id do
    @title = "Correct order #{params[:id]}"
    @cats = KSM::Category.all.select{ |c| c.category_id.nil? }.sort_by(&:wfindex)
    order = Order.find(params[:id])
    @order_lines = order.order_lines
    @total = order.total
    @id = order.id
    @order_client = order.client
    place = CabiePio.get([:orders, :towns], order.id).data
    @order_place = KatoAPI.anything(place) if place
    @place = place
    @descr = order.description
    @form = order
    @cash = CabiePio.get([:orders, :cash], order.id).data == 't'
    @cattree = otree_cats3 cats_olist
    @protree = otree_rendered place
    render 'orders/empty'
  end

  post :save, :with => :id do
    order = Order.find(params[:id])
    order.delivery = params[:order][:delivery].to_i
    order.priority = params[:order][:priority] == 'true'
    order.description = params[:order][:description]
    order.client_id = params[:order]["client_id"]
    order.place_id = params[:order]["place_id"]
    code = params[:cabie][:kato_place]
    if Kato.valid? code
      CabiePio.set [:orders, :towns], order.id, code
    end
    cash = params[:order][:cash] == 'true' ? 't' : 'f'
    CabiePio.set [:orders, :cash], order.id, cash
    if params[:light_edit]
      o_ship = KSM::OrderShip.find(order.id)
      o_ship.clear_formize params[:ship]
      o_ship.save
      order.save
      redirect url(:orders, :choosie, id: order.id)
    end

    order.status = order.draft? ? :draft : :anew
    order.done_parts = 0
    order.total = 0
    order.done_total = 0
    # order = order.attributes.merge({ :status => :anew, :online_at => order.created_at })
    # order = Order.new({:online_id => online.id, :status => :anew, :client_id => client, :online_at => online.created_at, :description => online.description, :total => online.total})
    sections_draft = []
    exst = params[:line].map{|l|l[:ol].to_i}
    order_rm = Order.new
    order.order_lines_ar.each do |ol|
      next if exst.include? ol.id
      ol.amount = 0
      order_rm.order_lines << ol
      ol.destroy
      KSM::OrderLine.find(ol.id).remove
      sections_draft << product_to_section(ol.product_id)
    end
    params[:line].each do |line|
      p = Product.find(line['id']) rescue nil
      next if !p
      next unless p.exist?
      if col = order.order_lines_ar.detect{|l|l.id == line[:ol].to_i}
        sections_draft << product_to_section(p.id) unless col.amount == line[:amount].to_i
        col.amount = line[:amount]
        col.description = line[:comment]
        order.total += p.price*col.amount
        col.save
      else
        sections_draft << product_to_section(p.id)
        ol = OrderLine.new({ :product_id => p.id, :amount => line['amount'], :price => p.price, :description => line['comment'] })
        order.total += p.price*ol.amount
        order.order_lines_ar << ol
      end
      # ol.update_attributes(l)
    end
    order.save

    # old_parts = order.order_parts.map{|p|[p.section_id, p.state]}.to_h
    # order.order_parts.destroy_all
    o_status = KSM::OrderStatus.find(order.id)
    o_status.setg(order.draft? ? :draft : :anew)
    old_parts = o_status.pstate.map{|k,v|[k, o_status.state(k)]}.to_h
    o_status.pstate = {}
    sections = KSM::Section.all
    sections.each do |s|
      include_section = false
      s.categories.each do |c|
        include_section = order.by_cat?(c.id)
        break if include_section
      end
      found = order.order_parts.detect{|op|op.section_id == s.ix}
      if include_section
        state = old_parts[s.ix] || :anew
        state = :anew if sections_draft.include? s.id
        old_state = state == :prepare ? :current : state
        op = OrderPart.new(:section_id => s.ix, :state => old_state)
        order.order_parts << op unless found
        found.update(state: old_state) if found
        o_status.sets(s.ix, state)
      elsif found
        found.destroy
      end
    end

    o_status.save
    order.all_parts = order.order_parts.size if order.order_parts.any?
    order.save
    order.actualize
    calc_complexity_for order
    # arbal_need_order_rep(order)
    arbal_need_order_edit(order) unless order.draft?
    arbal_need_order_edit(order_rm) unless order.draft?
    
    redirect url(:orders, :choosie, id: order.id)
  end

  put :anew do
    order = Order.find(params[:id])
    if order.draft?
      delivery_at = params[:timeline_at]
      if timeline_date = Date.parse(delivery_at) rescue nil
        CabiePio.set %i[anewdate order], timeline_order(order.id), order.id
        CabiePio.set %i[orders anewdate], order.id, timeline_id

        unassign_sticker_days order.id
        sow = calc_sticker_sow order.id, timeline_date
        assign_sticker_days order.id, sow

        td = stadie_done order.id
        CabiePio.set %i[timeline order], timeline_order(order.id, td), order.id
        CabiePio.set %i[orders timeline], order.id, timeline_id(td)

        order.status = :anew
        order.save
        o_status = KSM::OrderStatus.find(order.id)
        o_status.setg(:anew)
        o_status.save
      else
        return { error: true }.to_json
      end
    end
    { }.to_json
  end

  put :backdraft, :with => :id do
    order = Order.find(params[:id])
    o_status = KSM::OrderStatus.find(order.id)
    sections = o_status.pstate.keys
    if o_status.what?(:anew)
      current_kc = CabiePio.get([:orders, :timeline], order.id).data
      current_tl = timeline_unf(current_kc) if current_kc
      CabiePio.unset [:timeline, :order], timeline_order(order.id, current_tl) if current_kc
      CabiePio.unset [:orders, :timeline], order.id

      current_an = CabiePio.get([:orders, :anewdate], order.id).data
      current_da = timeline_unf(current_an) if current_an
      CabiePio.unset [:anewdate, :order], timeline_order(order.id, current_da) if current_an
      CabiePio.unset [:orders, :anewdate], order.id

      order.status = :draft
      order.save

      o_status.setg(:draft)
      o_status.save

      arbal_need_order_rep(order)
    end
    redirect url(:orders, :index)
  end

  put :toship do
    oids = params[:oid].split(',').map(&:to_i)
    oids.each do |oi|
      order = Order.find oi
      o_status = KSM::OrderStatus.find oi
      
      order.status = :shipready
      order.save

      o_status.setg(:shipready)
      o_status.save
    end
    n = (storebox(:counters, :shipready) || []) - oids + oids
    storebox_set(:counters, :shipready, n)
    redirect url(:orders, :finished)
  end

  put :ship do
    oids = params[:oid].split(',').map(&:to_i)
    oids.each do |oi|
      order = Order.find oi
      o_status = KSM::OrderStatus.find oi
      
      order.status = :shipped
      order.save

      o_status.setg(:shipped)
      o_status.save
    end
    n = (storebox(:counters, :shipready) || []) - oids
    storebox_set(:counters, :shipready, n)
    redirect url(:orders, :shipready)
  end

  patch :readship, :provides => :json do
    oids = params[:oid].split(',').map(&:to_i)
    n = (storebox(:counters, :shipready) || []) - oids
    storebox_set(:counters, :shipready, n)
    {}.to_json
  end

  get :ship, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    if @order.finished?
      @order.track = "VO34888864"
      @order.status = :shipped
      @order.save
      o_status = KSM::OrderStatus.find(@order.id)
      o_status.setg(:shipped)
      o_status.save
      flash[:success] = 'Заказ отправлен и у него есть номер накладной'
      redirect(url(:orders, :finished))
    end
    redirect(url(:orders, :finished))
  end

  put :draftbw, :with => :id do
    order = Order.find(params[:id])
    o_status = KSM::OrderStatus.find(order.id)
    o_status.gdraft = params[:state]
    o_status.save
    {}.to_json
  end

  put :status, :with => :id do
    order = Order.find(params[:id])
    s = params[:section]
    my_section = KSM::Section.find(s || current_account.section_id).ix
    order_part = order.order_parts.find_by(:section_id => my_section)
    if order_part.anew?
      order_part.state = :current if order_part.anew?
      order_part.save
      order.status = :current
      order.save

      status = KSM::OrderStatus.find(order.id)
      status.set_prepare(my_section)
      status.setg(:prepare)
      status.save

      o_life = KSM::OrderLife.find(order.id)
      o_life.ts_prepare(my_section)
      o_life.save

      arbal_need_order_start order
    end
    true.to_json
    # redirect url(:orders, :edit, :id => order.id)
  end

  put :midstatus, :with => :id do
    order = Order.find(params[:id])
    s = params[:section]
    my_section = KSM::Section.find(s || current_account.section_id).ix
    order_part = order.order_parts.find_by(:section_id => my_section)
    status = KSM::OrderStatus.find(order.id)
    status.set_current(my_section)
    status.setg(:current) if status.present?(1) && order_part.section_id == 1
    status.setg(:current) unless status.present?(1)
    status.save

    o_life = KSM::OrderLife.find(order.id)
    o_life.ts_current(my_section)
    o_life.save
    true.to_json
    # redirect url(:orders, :edit, :id => order.id)
  end

  put :update, :with => :id do
    if params[:unblink]
      order = Order.find(params[:id])
      CabiePio.unset [:orders, :timeline_blink], order.id
      redirect url(:orders, :edit, id: order.id)
    end

    @title = pat(:update_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    id_part = params[:next_status]
    @order_part = @order.order_parts.find_by(:section_id => id_part)
    @order_part ||= @order.order_parts.find_by(:section_id => current_account.section)
    # @order.status = params[:status]
    # @order.priority = params[:priority] == "true"
    delivery_at = params[:cabie][:timeline_at] rescue nil
    if timeline_date = Date.parse(delivery_at) rescue nil
      current_kc = CabiePio.get([:orders, :timeline], @order.id).data
      current_tl = timeline_unf(current_kc) if current_kc
      CabiePio.unset [:timeline, :order], timeline_order(@order.id, current_tl) if current_kc
      # CabiePio.set [:timeline, :order], timeline_order(@order.id, timeline_date), @order.id
      # CabiePio.set [:orders, :timeline], @order.id, timeline_id(timeline_date)
      CabiePio.set([:orders, :timeline_blink], @order.id, 1) if timeline_date != current_tl

      unassign_sticker_days @order.id
      sow = calc_sticker_sow @order.id, timeline_date
      assign_sticker_days @order.id, sow

      td = stadie_done @order.id
      CabiePio.set %i[timeline order], timeline_order(@order.id, td), @order.id
      CabiePio.set %i[orders timeline], @order.id, timeline_id(td)
      @order.touch
    end
    
    next_all = params[:next_status_all] || params[:next_status_all_force]
    order_part_st = @order.order_parts.find_by(:section_id => 1)
    part_before = order_part_st&.current?

    o_status = KSM::OrderStatus.find(@order.id)
    if @order_part && params[:order_part]
      # @order_part.status = params[:order_part]['done'] ? :finished : :current
      ks = KSM::Section.all.detect { |s| s.ix == @order_part.section_id }
      opf = params[:order_part][ks.id]
      if opf
        @order_part.boxes = opf[:boxes] || 0
        @order_part.boxes = 0 if opf[:no_boxes] == '1'
      end
      # @order_part.transfer = params[:order_part][@order_part.section_id][:transfer] || false
      @order_part.state = :finished if params[:next_status]
      @order_part.save
      o_status.sets(@order_part.section_id, :finished) if params[:next_status]
      # o_status.setg(:current) if params[:next_status]
      # @order_part.update_attributes(params[:order_part])
    end
    if next_all
      @order.order_parts.each do |part|
        part.state = :finished
        part.save
        o_status.sets(part.section_id, :finished)
      end
    end
    o_status.save

    params[:line].each do |line|
      l = line.second
      # l = line.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      # break if l[:id].blank?
      next if l['id'].nil?
      ol = @order.order_lines_ar.find(l['id'])
      if l['done_amount']
        if l['done_amount'].size < 1
          l.delete('done_amount')
          ol.done_amount = nil
        else
          l['done_amount'] = l['done_amount'].to_i rescue 0
        end
      end
      ol.update_attributes(l)
    end
    sticker_sum = 0
    saved_stickers = CabiePio.all_keys(@order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker])
      .flat.trans(:to_i).transform_values{|v|v[:v]}
    kc_products = CabiePio.folder(:products, :sticker).flat.trans(nil, :to_f)
    amt = 0
    @order.order_lines.each do |ol|
      sq = kc_products.fetch(ol.product_id, 0)
      next if sq == 0 || ol.ignored 
      amt += sq*(ol.done_amount || 0 > 0 ? ol.done_amount : ol.amount)
    end
    prev_amt = CabiePio.get([:orders, :stickers_amount], @order.id).data.to_i
    save_stickers_amount(@order.id, amt) if amt != prev_amt

    # params[:line_s].each do |line_id, line_v|
    #   next unless line_id
    #   ol = @order.order_lines.find(line_id)
    #   next if ol.ignored
    #   ols = line_v['sticker'].to_i rescue 0
    #   sticker_sum += ols*kc_products.fetch(ol.product_id, 0)
    #   next if saved_stickers[ol.id] == ols
    #   save_sticker_line(ol.id, ols) if ols > 0
    # end if params[:line_s]
    # operc = to_perc(amt, sticker_sum)
    # if operc > 0
    #   save_sticker_history(@order.id, operc)
    #   save_sticker_progress(@order.id, operc)
    # end
    
    status_before = @order.current? || @order.anew? || [:current, :anew, :prepare].include?(o_status.state)
    status_fin = false
    @order.done_parts = @order.order_parts.where("state = ?", OrderPart.states[:finished]).size
    if @order.done_parts == @order.all_parts || next_all
      amount = 0.0
      @order.order_lines.each do |ol|
        next if ol.ignored
        amount += ol.price*(ol.done_amount || 0)
      end
      @order.done_total = amount
      status_fin = true
    end
    @order.status = :finished if status_fin
    @order.track = params[:track]
    @order.save
    @order.actualize
    calc_complexity_for @order

    # arbal_need_order_mid(@order) if @order.current?
    
    if part_before && order_part_st.finished?
      arbal_need_order_st_fin(@order)
    end
    if status_before && @order.finished?
      arbal_need_order_done(@order)
      arbal_need_order_fin(@order)

      o_status = KSM::OrderStatus.find(@order.id)
      o_status.setg(:finished)
      o_status.save
    end

    if @order.finished?
      redirect url(:orders, :invoice, id: @order.id)
    else
      redirect url(:orders, :edit, id: @order.id)
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
    @order = Order.includes(:order_lines_ar).find(params[:id])
    @sections = KSM::Section.all
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
      ol = @order.order_lines_ar.find(i)
      ol.update_attributes(l)
    end

    @order = Order.find(params[:id])
    amount = 0.0
    @order.order_lines_ar.each do |ol|
      next if ol.ignored
      amount += ol.price*(ol.done_amount||0)
    end
    @order.done_total = amount
    @order.save

    redirect(url(:orders, :price, :id => params[:id]))
  end

  get :buncha do
    render 'orders/bunch'
  end

  post :bunch do
    ids = params[:ksm_draw][:orders].join(',')
    redirect url(:orders, :bunch, id: ids.to_s)
  end

  get :bunch, :with => :id, :provides => :html do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    ids = params[:id].split(',').map(&:to_i)
    @orders = Order.where(id: ids)
    @sections = KSM::Section.all
    # habits(@sections, :index)
    @my_section = @sections.detect{ |a| a.ix == current_account.section_id }

    @order = OrderBunch.new
    @orders.each do |order|
      order.order_lines.each do |ool|
        @order.order_lines << OrderLineBun.new(ool.serializable_hash)
      end
      
      @order.total += order.total
      @order.done_total += order.done_total
    end
    @kc_products = CabiePio.folder(:products, :sticker).flat

    render 'orders/bunch_view'    
  end

  get :bunch, :with => :id, :provides => :csv do
    ids = params[:id].split(',').map(&:to_i)
    @orders = Order.where(id: ids)
    @sections = KSM::Section.all
    # habits(@sections, :index)

    @order = OrderBunch.new
    @orders.each do |order|
      order.order_lines.each do |ool|
        @order.order_lines << OrderLineBun.new(ool.serializable_hash)
      end
      
      @order.total += order.total
      @order.done_total += order.done_total
    end
    gol = @order.order_lines.group_by(&:product_id)
    
    fname = 'orders.csv'
    headers['Content-Disposition'] = "attachment; filename=#{fname}"
    output = ''
    output = "\xEF\xBB\xBF" if params.include? :win
    output << CSV.generate(:col_sep => ';') do |csv|
      csv << [:name, ids, :sum].flatten
      @sections.sort_by(&:ix).each_with_index do |s, i|
        next unless tab_visible = @order.by_sec?(s.id)
        s.categories.sort_by(&:wfindex).each do |tab|
          next unless cat_visible = @order.by_cat?(tab.id)
          cp = nil
          @order.by_cat(tab.id).sort_by{|a|a.product.cindex}.each do |ol|
            next if cp == ol.product_id
            cp = ol.product_id
            por = []
            ids.each do |oid|
              por << gol[ol.product_id].select{ |gr| gr.order_id == oid }.sum(&:amount)
            end
            csv << [ol.product.displayname, por, gol[ol.product_id].sum(&:amount)].flatten
          end
        end
      end
    end
  end

  delete :destroy, :with => :id do
    # TODO: Delete order from tables
    @title = "Orders"
    order = Order.find(params[:id])
    if order && order.draft?
      if order.order_parts.destroy_all && order.order_lines_ar.destroy_all && order.destroy
        ostatus = KSM::OrderStatus.find(order.id)
        ostatus.setg(:canceled)
        ostatus.save
        flash[:success] = pat(:delete_success, :model => 'Order', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'order')
      end
      Timeline.destroy_all(:order_id => order.id)
      tl = CabiePio.get [:orders, :timeline], order.id
      CabiePio.unset [:timeline, :order], timeline_order(order.id, timeline_unf(tl.data)) if tl.data
      CabiePio.unset [:orders, :timeline], order.id
      redirect url(:orders, :draft)
    else
      flash[:warning] = pat(:delete_warning, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    halt 403
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
    @order = Order.find(params[:id])
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
    @order = Order.find(params[:id])
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
    { products: json_products_list(params[:place]), categories: json_cats_list }.to_json
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
    q = params[:q].gsub(/[^\wА-ЯЁа-яё \-0-9A-Za-z\.@]/, ' ')[0..32]

    # Client.joins(:place).where('umlike(?, lower("clients"."name"))', q)
    # .where('umlike(?, lower("clients"."name")) OR umlike(?, lower("places"."name"))', q, q)
    # cts = Place.where('umlike(?, lower(name))', q).pluck(:id)

    res = Client.where('umlike(?, lower(name))', q)
    res = Client.where('lower(email) LIKE ?', "%#{q}%") if q.include?('@')
    res = Client.where('tel LIKE ?', "%#{q}%") if q.index(/\A[0-9]+\Z/)
    # res << Client.joins(:place)
    #   .where('umlike(?, lower("places"."name"))', q)
    #   .select("clients.id, clients.name, places.name as city").first(20)
    res = res.select("clients.id, clients.name, clients.id as city").first(15)
    kc_clients = CabiePio.all_keys(res.map(&:id), folder: [:clients, :hometowns]).flat.trans(:to_i)
    kc_towns = KatoAPI.batch(kc_clients.values.uniq)
    res.each do |item|
      item.city = kc_towns[kc_clients[item.city]]&.model&.name
    end
    res.to_json
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

  post :stickers_info, :provides => :json do
    order = params[:order].to_i
    amt = deli(order_sticker(order).sum.ceil)
    start = Date.parse(params[:date]) rescue nil
    return { id: order, amount: amt }.to_json unless start
    sowa = calc_sticker_sow(order, start)
    ar = sowa.keys.map{|k|k.strftime("%-d")}
    lapse = stadie_pregap order
    dl = (sowa.keys.first - lapse) - Date.today
    { id: order, amount: amt, dates: ar, amdelay: dl.to_i }.to_json
  end
end
