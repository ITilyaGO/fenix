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
    # @timelines = Timeline.all.order(:updated_at => :desc)
    @prev = Date.today.beginning_of_week
    @prev_end = @prev.end_of_week
    @prev2 = @prev.prev_week
    @prev2_end = @prev2.end_of_week
    @next = Date.today.next_week
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
    @weeks << { :name => "Пред. неделя", :date => @prev2, :end => @prev2_end, :orders => Timeline.where("duration = ? AND start_at BETWEEN DATE(?) AND DATE(?)", Timeline.durations[:week], @prev2, @prev2.next) }
    @weeks << { :name => "Эта неделя", :date => @prev, :end => @prev_end, :orders => Timeline.where("duration = ? AND start_at BETWEEN DATE(?) AND DATE(?)", Timeline.durations[:week], @prev, @prev.next) }
    @weeks << { :name => "Следующая неделя", :date => @next, :end => @next_end, :orders => Timeline.where("duration = ? AND start_at BETWEEN DATE(?) AND DATE(?)", Timeline.durations[:week], @next, @next.next) }
    @weeks << { :name => "Через одну неделю", :date => @next2, :end => @next2_end, :orders => Timeline.where("duration = ? AND start_at BETWEEN DATE(?) AND DATE(?)", Timeline.durations[:week], @next2, @next2.next) }
    @weeks << { :name => "", :date => @next3, :end => @next3_end, :orders => Timeline.where("duration = ? AND start_at BETWEEN DATE(?) AND DATE(?)", Timeline.durations[:week], @next3, @next3.next) }
    @weeks << { :name => "", :date => @next4, :end => @next4_end, :orders => Timeline.where("duration = ? AND start_at BETWEEN DATE(?) AND DATE(?)", Timeline.durations[:week], @next4, @next4.next) }
    @weeks << { :name => "", :date => @next5, :end => @next5_end, :orders => Timeline.where("duration = ? AND start_at BETWEEN DATE(?) AND DATE(?)", Timeline.durations[:week], @next5, @next5.next) }
    @weeks << { :name => "", :date => @next6, :end => @next6_end, :orders => Timeline.where("duration = ? AND start_at BETWEEN DATE(?) AND DATE(?)", Timeline.durations[:week], @next6, @next6.next) }

    @timelines1 = Timeline.where(:start_at => @next)
    @timelines1 = Timeline.where(:start_at => @next2)
    # @pages = (Order.count/pagesize).ceil
    # @r = url(:orders, :index)

    @o = Order.all.where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:shipped])
    @orders_for_select = []
    @o.each do |order|
      client = order.client.name
      name = [order.id, client, order.place_name, to_dm(order.created_at)].reject(&:blank?).join(" / ")
      date = !order.timeline.nil? ? order.timeline.start_at : nil
      @orders_for_select << { :name => name, :date => date, :value => order.id  }
    end

    @sections = Section.includes(:categories).all

    render 'timeline/weeks'
  end

  # get :new, :with => :id do
  #   @title = "New order"
  #   @online = Online::Order.includes(:order_lines).find(params[:id])
  #   a = @online.account
  #   @client = Client.find_by(online_id: @online.account_id)
  #   if !@client
  #     t = Client.arel_table
  #     @clients = Client.where(t[:city].matches(a.city).or(t[:tel].matches(a.tel)).or(t[:email].matches(a.email)))
  #     @clients = Client.all if !@clients.any?
  #   end
  #   render 'orders/new'
  # end

  # post :create do
  #   # @order = Order.new(params[:order])
  #   # cats = Category.where(:category => nil)
  #   # where(:category => nil)@tabs.each do |tab|
  #
  #   client = params[:order]["client_id"]
  #   online = Online::Order.includes(:order_lines).find(params[:id])
  #   # order = online.attributes.merge({:online_id => online.id, :status => :anew, :client_id => params[:order][:client_id]})
  #   # h = Order.new
  #   # h.attributes.merge(order.slice(*h.attributes))
  #   # order = order.slice([:account_id])
  #   # order.delete(:account_id)
  #   # h.save
  #   order = Order.new({:online_id => online.id, :status => :anew, :client_id => client, :online_at => online.created_at, :description => online.description, :total => online.total})
  #   online.order_lines.each do |line|
  #     ol = OrderLine.new(product_id: line.product_id, description: line.description, amount: line.amount, price: line.sum/line.amount)
  #     order.order_lines << ol
  #   end
  #   order.save
  #
  #   sections = Section.all
  #   sections.each do |s|
  #     include_section = false
  #     s.categories.each do |c|
  #       include_section = order.by_cat?(c.id)
  #       break if include_section
  #     end
  #     if include_section
  #       op = OrderPart.new(section_id: s.id)
  #       order.order_parts << op
  #     end
  #   end
  #   order.all_parts = order.order_parts.size if order.order_parts.any?
  #
  #   order.save
  #   redirect(url(:orders, :index))
  #   if @order.save
  #     @title = pat(:create_title, :model => "order #{@order.id}")
  #     flash[:success] = pat(:create_success, :model => 'Order')
  #     params[:save_and_continue] ? redirect(url(:orders, :index)) : redirect(url(:orders, :edit, :id => @order.id))
  #   else
  #     @title = pat(:create_title, :model => 'order')
  #     flash.now[:error] = pat(:create_error, :model => 'order')
  #     render 'orders/new'
  #   end
  # end

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
    @title = pat(:update_title, :model => "order #{params[:id]}")
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
