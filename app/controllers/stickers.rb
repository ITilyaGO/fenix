Fenix::App.controllers :stickers do
  get :orders do
    @title = "Все наклееные заказы"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"
    orders_query = Order.where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished])
    orders_query = orders_query.where(delivery: params[:deli].to_i) if params[:deli]
    
    prev_m = Date.today.next_month(-1).strftime('%y%m')
    last1_stickers = CabiePio.all([:i, :orders, :sticker_date], [timeline_id[0...4]]).flat.keys
    last2_stickers = CabiePio.all([:i, :orders, :sticker_date], [prev_m]).flat.keys
    last_stickers = (last1_stickers + last2_stickers)
      .sort.map{|k|k.split(Fenix::App::IDSEP).last.to_i}.reverse.shift(150)
    # @orders = orders_query.includes(:client, :place, :order_parts, :timeline).order(sort => dir)
    if current_account.limited_orders?
      @filtered_by_user = OrderPart.where(:order_id => orders_query.ids, :section => current_account.section_id).pluck(:order_id)
    end
    @orders = Order.where(id: last_stickers).sort_by{|o|last_stickers.index(o.id)}
    @pages = (orders_query.count/pagesize).ceil
    @sections = Section.includes(:categories).all
    a_managers(@orders.map(&:id), @orders.map(&:client_id))
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    @kc_stickers = CabiePio.all_keys(@orders.map(&:id), folder: [:sticker, :order_progress]).flat.trans(:to_i, :to_f)
    @r = url(:stickers, :orders)
    render 'orders/index'
  end

  get :order, :with => :id do
    @day = Date.parse(params[:date]) rescue Date.today.prev_day
    @title = pat(:edit_title, :model => "stickers for #{params[:id]}")
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

    ol_with_day = @order.order_lines.map(&:id).map{|ol| "#{ol}_#{timeline_id(@day)}" }
    @olstickers = CabiePio.all_keys(ol_with_day, folder: [:m, :order_lines, :sticker]).flat
      .transform_keys{|k|k.split(Fenix::App::IDSEP).first.to_i}
    @olsum = CabiePio.all_keys(@order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum]).flat.trans(:to_i)

    kc_amt = CabiePio.get([:orders, :stickers_amount], @order.id).data.to_i
    @sticker_progress = sticker_order_progress(@order.id)
    @kc_products = CabiePio.folder(:products, :sticker).flat.trans(:to_i)

    kc_town_managers = CabiePio.folder(:towns, :managers).flat
    hier = Kato::Hier.for(@kc_client_hometown).codes
    manager = kc_town_managers.fetch(hier.detect{|c| kc_town_managers[c]}, 0)
    @manager = Manager.find(manager) rescue nil
    @timeline_at = CabiePio.get([:orders, :timeline], @order.id).data
    @timeline_date = timeline_unf(@timeline_at) unless @timeline_at.nil?

    @history = CabiePio.get([:m, :sticker, :order_history], @order.id).data || {}
    @add_days = @history&.keys&.map{|d| timeline_unf d} || []
    @add_days << @day
    # calendar_init(Date.today)
    # @ps = KSM::OrderImage.all_for(@order.id)

    if @order
      # @order.actualize
      render 'stickers/order'
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    @order_part = @order.order_parts.find_by(:section_id => current_account.section)
    day = Date.parse(params[:day])

    # saved_stickers = CabiePio.all_keys(@order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker])
    #   .flat.trans(:to_i).transform_values{|v|v[:v]}
    # kc_products = CabiePio.folder(:products, :sticker).flat.trans(:to_i, :to_f)

    sticker_sum = 0
    saved_stickers = CabiePio.all_keys(@order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum])
      .flat.trans(:to_i).transform_values{|v|v[:v]}
    kc_products = CabiePio.folder(:products, :sticker).flat.trans(:to_i, :to_f)
    amt = 0
    @order.order_lines.each do |ol|
      sq = kc_products.fetch(ol.product_id, 0)
      next if sq == 0 || ol.ignored 
      amt += sq*(ol.done_amount || 0 > 0 ? ol.done_amount : ol.amount)
    end
    prev_amt = CabiePio.get([:orders, :stickers_amount], @order.id).data.to_i
    save_stickers_amount(@order.id, amt) if amt != prev_amt
    stickers_total = CabiePio.get([:orders, :stickers_amount], @order.id).data.to_i

    params[:stickers].each do |line_id, line_v|
      next unless line_id
      ol = @order.order_lines.find(line_id)
      next if ol.ignored || line_v.length == 0
      ols = line_v.to_i rescue 0
      # next if saved_stickers[ol.id] == ols
      save_sticker_line(ol.id, ols, day)
    end
    sticker_sum = calc_sticker_sum(@order.order_lines)
    operc = to_perc(stickers_total, sticker_sum)
    opercd = to_perc(stickers_total, calc_sticker_sum_for_day(@order.order_lines, day))
    if operc > 0
      save_sticker_history(@order.id, opercd, day)
      save_sticker_progress(@order.id, operc)
    end
    now_stickers = CabiePio.all_keys(@order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum])
      .flat.trans(:to_i).transform_values{|v|v[:v]}
    dilines = now_stickers.map{|k,v|[k,v-saved_stickers.fetch(k,0)]}.to_h
    arbal_unstock_order(@order, dilines, now_stickers)

    redirect(url(:orders, :index))
  end
end