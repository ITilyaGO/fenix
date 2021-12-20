Fenix::App.controllers :draws do
  get :index do
    @title = "Все тиражи"
    # @draws = KSM::Draw.all.sort_by{|a|a.sortname}.reverse

    @draws = kc_daydraws(Date.today) + kc_daydraws(Date.today - 1) + kc_daydraws(Date.today - 2)
    current = wonderbox(:draws_stack) || []
    @cdraws = KSM::Draw.find_all(current).sort_by{|a|a.sortname}.reverse
    @prday = (Date.today+1).strftime('%d.%m.%Y')

    render 'draws/index'
  end

  get :create do
    @title = "Создать тираж"
    @supermodel = KSM::Draw.new({})
    @supermodel.name = "#{(Date.today).strftime('%d.%m.%Y')}"
    # @plsn = draw_seed_get
    render 'draws/create'
  end

  get :edit, :with => :id do
    @title = "Тираж"
    @supermodel = KSM::Draw.find(params[:id])
    @supermodel.name = "#{(Date.today).strftime('%d.%m.%Y')}"
    # @supermodel.sns = @supermodel.sn
    # @supermodel.more = "#{(Date.today).strftime('%d.%m.%Y')}"
    # @plsn = draw_seed_get
    render 'draws/create'
  end

  get :orders do
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
    @sections = Section.includes(:categories).all
    a_managers(@orders.map(&:id), @orders.map(&:client_id))
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat
    @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i)
    @kc_blinks = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline_blink]).flat.trans(:to_i)
    @kc_stickers = CabiePio.all_keys(@orders.map(&:id), folder: [:sticker, :order_progress]).flat.trans(:to_i, :to_f)
    @orders = @orders.sort_by{|o|@kc_timelines[o.id]||''} if params[:seq] == "timeline"
    @orders = @orders.sort_by{|o|@kc_towns[@kc_orders[o.id.to_s]]&.model&.name||''} if params[:seq] == "city"
    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i).reject{|k,v|v!='t'}
    @r = url(:draws, :orders)
    @ra = [:draws, :orders]
    @rah = { deli: params[:deli] } if params[:deli]
    render 'draws/orders'
  end

  post :create do
    form = params[:ksm_draw]
    form[:more] = nil if form[:more].empty?
    day = Date.strptime form[:name], '%d.%m.%Y'
    sni = form[:sn].to_i
    max = draw_seed_max(day)
    dumb = KSM::Draw.new(sn: sni, type: form[:type])
    daynumtk = draw_seed_taken?(day, dumb.common)
    sn = sni > 0 ? sni : draw_seed_for(day)
    if daynumtk
      flash.now[:warning] = "Duplicate Error: #{dumb.common}"
      return render 'draws/error'
    end
    @draw = KSM::Draw.nest day, sn
    @draw.fill type: form[:type].to_sym, amount: form[:amount].to_i, more: form[:more], merge: true
    @draw.save
    draws_stack_push @draw.id
    form[:orders]&.each do |fo|
      draw_and_order_set @draw.id, fo
    end
    redirect url(:draws, :index)
  end

  post :to_print, :provides => :json do
    day = Date.strptime params[:day], '%d.%m.%Y'
    fdraws = params[:draws].split(',')
    draws = KSM::Draw.find_all fdraws
    draws.each do |fdraw|
      fdraw.printed = day
      fdraw.save
    end
    draws_stack_pop fdraws

    [day, fdraws].to_json
  end

  post :for_order, :provides => :json do
    draw_ids = order_draws_for(params[:order])
    draws = KSM::Draw.find_all(draw_ids).map(&:to_jr)

    draws.to_json
  end

end