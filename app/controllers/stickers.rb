Fenix::App.controllers :stickers do
  get :orders do
    @title = "Все наклееные заказы"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    sort = params[:sort] || "updated_at"
    dir = !params[:sort] && !params[:dir] ? "desc" : params[:dir] || "asc"
    if role_is? :manager
      orders_base = Order.in_work.pluck(:client_id)
      search_clients = Client.where(id: orders_base, manager_id: current_account.id).pluck(:id)
      orders_query = Order.where(client_id: search_clients).in_work
    else
      orders_query = Order.in_work
    end
    orders_query = orders_query.where(delivery: params[:deli].to_i) if params[:deli]
    
    mnths = timeline_months Date.today.next_month(-1)
    last_stickers = CabieAssist.focus([:i, :orders, :sticker_date], mnths)
      .sort.map{|k|k.split(Fenix::App::IDSEP).last.to_i}.reverse.shift(150)
    # @orders = orders_query.includes(:client, :place, :order_parts, :timeline).order(sort => dir)
    if current_account.limited_orders?
      @filtered_by_user = OrderPart.where(:order_id => orders_query.ids, :section => current_account.section_id).pluck(:order_id)
    end
    last_stickers = last_stickers & orders_query.ids
    @orders = Order.where(id: last_stickers).sort_by{|o|last_stickers.index(o.id)}
    @pages = (orders_query.count/pagesize).ceil
    @sections = KSM::Section.all
    a_managers(@orders.map(&:id), @orders.map(&:client_id))
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    @kc_blinks = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline_blink]).flat.trans(:to_i)
    @kc_stickers = CabiePio.all_keys(@orders.map(&:id), folder: [:sticker, :order_progress]).flat.trans(nil, :to_f)
    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i).reject{|k,v|v!='t'}
    @orders = @orders.sort_by{|o|@kc_timelines[o.id]}.reverse if params[:seq] == "timeline"
    @r = url(:stickers, :orders)
    @ra = [:stickers, :orders]
    render 'orders/index'
  end

  get :order, :with => :id do
    @day = Date.parse(params[:date]) rescue Date.today.prev_day
    @title = pat(:edit_title, :model => "stickers for #{params[:id]}")
    @order = Order.includes(:order_lines_ar).find(params[:id])
    @sections = KSM::Section.all
    @my_section = @sections.detect{ |a| a.ix == current_account.section_id }
    @order_part = @order.order_parts.find_by(:section_id => @my_section&.ix)
    @tabs = Category.where(:category => nil)

    @kc_client_hometown = CabiePio.get([:clients, :hometowns], @order.client.id).data
    @kc_client_delivery = CabiePio.get([:clients, :delivery_towns], @order.client.id).data
    @kc_order_town = CabiePio.get([:orders, :towns], @order.id).data
    @kc_order_delivery = CabiePio.get([:orders, :delivery_towns], @order.id).data
    @kc_towns = KatoAPI.batch([@kc_client_hometown, @kc_client_delivery, @kc_order_town, @kc_order_delivery].compact)

    ol_with_day = @order.order_lines.map(&:id).map{|ol| "#{ol}_#{timeline_id(@day)}" }
    @olstickers = CabiePio.all_keys(ol_with_day, folder: [:m, :order_lines, :sticker]).flat
      .transform_keys{|k|k.split(Fenix::App::IDSEP).first}
    @olsum = CabiePio.all_keys(@order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum]).flat

    kc_amt = CabiePio.get([:orders, :stickers_amount], @order.id).data.to_i
    @sticker_progress = sticker_order_progress(@order.id)
    @kc_products = CabiePio.folder(:products, :sticker).flat

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
    kc_products = CabiePio.folder(:products, :sticker).flat.trans(nil, :to_f)
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
      ol = @order.order_lines_ar.find(line_id)
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
    arbal_unstock_order(@order, dilines, now_stickers, day)

    redirect(url(:orders, :index))
  end

  get :pastline do
    @title = t "tit.stickers.pastline"
    @print_btn = 1
    start_from = timeline_unf(params[:start]) rescue Date.today
    bow = start_from.weeks_ago(2).beginning_of_week
    @weeks = []
    6.times do |i|
      @weeks << { :date => bow.weeks_ago(-i) }
    end
    
    ky_month_1 = start_from.strftime('%y%m')
    ky_month_2 = start_from.next_month.strftime('%y%m')
    ky_month_0 = start_from.prev_month.strftime('%y%m')
    @ktm = CabiePio.all([:timeline, :order], [ky_month_1]).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], [ky_month_0]).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], [ky_month_2]).flat
    @all_ids = @ktm.trans(nil, :to_i).map(&:last)

    @stickers = CabiePio.all_keys(@all_ids, folder: [:sticker, :order]).flat.trans(:to_i, :to_f)
    @glass_stickers = CabiePio.all_keys(@all_ids, folder: [:sticker, :order_glass]).flat.trans(:to_i, :to_f)
    @gweek = calendar_group(@ktm.trans(nil, :to_i))
    @sdate = start_from
    kc_stickers = CabiePio.folder([:products, :sticker]).flat.trans(nil, :to_f)
    @week_sum = { start_from.beginning_of_month.beginning_of_week => 0 }
    @day_sum = {}
    @glday_sum = {}

    @kts = CabiePio.query("m/order_lines/sticker>.*_#{ky_month_0}2.", type: :regex).flat
    @kts = @kts.merge CabiePio.query("m/order_lines/sticker>.*_#{ky_month_0}3.", type: :regex).flat
    # @kts = @kts.merge CabiePio.query("m/order_lines/sticker>.*_#{ky_month_1}..", type: :regex).flat
    @kts = @kts.merge CabiePio.query("m/order_lines/sticker>.*_#{ky_month_2}0.", type: :regex).flat
    @month_sum = CabiePio.query("m/order_lines/sticker>.*_#{ky_month_1}..", type: :regex).flat.sum do |i,k|
      ol = OrderLine.find(i.split('_').first.to_i) rescue nil
      s = k[:v]*kc_stickers.fetch(ol&.product_id, 0)
      day = timeline_unf(i.split('_').last)
      gd = day.beginning_of_week
      @day_sum[day] ||= 0
      @day_sum[day] += s
      if product_is_glass?(ol&.product_id)
        @glday_sum[day] ||= 0
        @glday_sum[day] += s
      end
      @week_sum[gd] ||= 0
      @week_sum[gd] += s
      s
    end
    @kts.each do |i,k|
      ol = OrderLine.find(i.split('_').first.to_i) rescue nil
      s = k[:v]*kc_stickers.fetch(ol&.product_id, 0)
      day = timeline_unf(i.split('_').last)
      gd = day.beginning_of_week
      @day_sum[day] ||= 0
      @day_sum[day] += s
      if product_is_glass?(ol&.product_id)
        @glday_sum[day] ||= 0
        @glday_sum[day] += s
      end
    end

    render 'stickers/pastline'
  end

end

Fenix::App.controllers :dr_pastline, :map => 'pastline/driven' do

  patch :stickers_info do
    @cdate = timeline_unf(params[:date]) rescue Date.today

    ky_day = @cdate.strftime('%y%m%d')
    ols = CabiePio.query("m/order_lines/sticker>.*_#{ky_day}", type: :regex).flat.keys
    
    ol_ids = ols.map{|kc|kc.split('_').first.to_i}.uniq
    @all_ids = ol_ids.map{|i|OrderLine.find_by(id: i)&.order_id}.compact.uniq
    # @tml = CabiePio.all([:timeline, :order], [ky_day]).flat

    # @all_ids = @tml.map(&:last).map(&:to_i)
    @orders = Order.where(id: @all_ids).order(:client_id)
    @stickers = CabiePio.all_keys(@all_ids, folder: [:sticker, :order_progress]).flat.trans(:to_i, :to_f)

    partial 'stickers/stickers_side'
  end
end