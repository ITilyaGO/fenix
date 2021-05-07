Fenix::App.controllers :timeline do
  get :index do
    @title = "Timeline"
    @timelines = Timeline.all.order(:updated_at => :desc)
    @prev = Date.today.beginning_of_week
    @prev2 = @prev.prev_week
    @next = Date.today.next_week
    @next2 = @next.next_week

    @timelines1 = Timeline.where(:start_at => @next)
    @timelines1 = Timeline.where(:start_at => @next2)
    # @pages = (Order.count/pagesize).ceil
    # @r = url(:orders, :index)
    render 'timeline/index'
  end

  get :orders do
    @title = "Orders"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @orders = Order.all.order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    @pages = (Order.count/pagesize).ceil
    @r = url(:orders, :index)
    render 'timeline/orders'
  end

  get :weeks do
    @title = "Timeline"
    @print_btn = 1
    start_from = timeline_unf(params[:start]) rescue Date.today
    @prev = start_from.beginning_of_week
    @prev_end = @prev.end_of_week
    @prev2 = @prev.prev_week
    @prev2_end = @prev2.end_of_week
    @next = start_from.next_week
    @next_end = @next.end_of_week
    @next2 = @next.next_week
    @next2_end = @next2.end_of_week
    @next3 = @next2.next_week
    @next3_end = @next3.end_of_week
    @next4 = @next3.next_week
    @next4_end = @next4.end_of_week
    @next5 = @next4.next_week
    @next5_end = @next5.end_of_week
    @next6 = @next5.next_week
    @next6_end = @next6.end_of_week
    @weeks = []

    @weeks << { :name => "Пред. неделя", :date => @prev2, :end => @prev2_end }
    @weeks << { :name => "Эта неделя", :date => @prev, :end => @prev_end }
    @weeks << { :name => "Следующая неделя", :date => @next, :end => @next_end }
    @weeks << { :name => "Через одну неделю", :date => @next2, :end => @next2_end }
    @weeks << { :name => "", :date => @next3, :end => @next3_end }
    @weeks << { :name => "", :date => @next4, :end => @next4_end }
    @weeks << { :name => "", :date => @next5, :end => @next5_end }
    @weeks << { :name => "", :date => @next6, :end => @next6_end }

    calendar_init(start_from)

    render 'timeline/weeks'
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    @timeline = @order.timeline || Timeline.new()
    @cats = Category.where(:category_id => nil)
    if @order
      render 'timeline/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "order #{params[:id]}")
    @order = Order.find(params[:id])
    @timeline = @order.timeline
    # Timeline.find(@order[:timeline_id])
    if @timeline
      if @timeline.update_attributes(params[:timeline])
        redirect(url(:timeline, :orders))
        # flash[:success] = pat(:update_success, :model => 'Order', :id =>  "#{params[:id]}")
        # params[:save_and_continue] ?
        #   redirect(url(:orders, :index)) :
        #   redirect(url(:orders, :edit, :id => @order.id))
      else
        halt 404
        flash.now[:error] = pat(:update_error, :model => 'order')
        render 'timeline/edit'
      end
    else
      @timeline = Timeline.create(params[:timeline].merge({:order_id => @order.id}))
      redirect(url(:timeline, :orders))
      # flash[:warning] = pat(:update_warning, :model => 'order', :id => "#{params[:id]}")
      # halt 404
    end
  end

  put :assign do
    # @order = Order.find(params[:id])
    s = params[:start]
    e = params[:end]
    params[:immediates].each do |o|
      timeline = Timeline.find_by(:order_id => o)
      if timeline
        timeline.start_at = s
        timeline.end_at = e
        timeline.duration = :week
        timeline.immediate = true
        timeline.save
      else
        timeline = Timeline.create({ :start_at => s, :end_at => e, :duration => :week, :order_id => o })
      end
    end rescue nil
    params[:orders].each do |o|
      timeline = Timeline.find_by(:order_id => o)
      if timeline
        timeline.start_at = s
        timeline.end_at = e
        timeline.duration = :week
        timeline.immediate = false
        timeline.save
      else
        timeline = Timeline.create({ :start_at => s, :end_at => e, :duration => :week, :immediate => false, :order_id => o })
      end
    end rescue nil
    redirect(url(:timeline, :weeks))
  end

  put :change do
    id = params[:timeline_id]
    order_id = id.split('_').last.to_i
    delivery_at = params[:timeline_at]
    if timeline_date = Date.parse(delivery_at) rescue nil
      CabiePio.unset [:timeline, :order], id
      CabiePio.set [:timeline, :order], timeline_order(order_id, timeline_date), order_id
      CabiePio.set [:orders, :timeline], order_id, timeline_id(timeline_date)
    end
    true
  end

  delete :destroy, :with => :id do
    @title = "Orders"
    order = Order.find(params[:id])
    if order
      if order.destroy
        flash[:success] = pat(:delete_success, :model => 'Order', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'order')
      end
      redirect url(:orders, :index)
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

end

Fenix::App.controllers :dr_timeline, :map => 'timeline/driven' do
  patch :orders do
    @title = "Timeline"
    @sdate = timeline_unf(params[:period])
    start_from = timeline_unf(params[:start]) rescue Date.today
    start_from = @sdate
    @prev = start_from.beginning_of_week
    

    ky_month_1 = start_from.strftime('%y%m')
    ky_month_2 = start_from.next_month.strftime('%y%m')
    @ktm = CabiePio.all([:timeline, :order], [ky_month_1]).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], [ky_month_2]).flat
    @gtm = timeline_group(@ktm.trans(nil, :to_i))

    @sections = Section.includes(:categories).all
    @orders = []
    @week_orders = @gtm.fetch(@sdate, [])
    @all_ids = @week_orders.map(&:last).map(&:to_i)
    @orders = Order.where(id: @all_ids).order(:client_id)
    a_managers(@all_ids, @orders.map(&:client_id).uniq)

    @stickers = CabiePio.all_keys(@all_ids, folder: [:sticker, :order]).flat.trans(:to_i, :to_f)
    @transport = CabiePio.all_keys(@orders.map(&:client_id).uniq, folder: [:m, :clients, :transport]).flat

    if params[:sort].to_sym == :manager
      @by_manager = @orders.map(&:id).group_by do |oid|
        fo = @orders.detect{|o| o.id == oid}
        next unless fo
        @kc_managers[@kc_hometowns[fo.client_id.to_s]]
      end
      partial 'timeline/orders_for_manager'
    elsif params[:sort].to_sym == :delivery
      @by_delivery = @orders.group_by(&:delivery)
      partial 'timeline/orders_for_delivery'
    else
      partial 'timeline/orders'
    end
  end
end