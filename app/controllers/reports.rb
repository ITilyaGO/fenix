Fenix::App.controllers :reports do
  get :index do
    render 'reports/index'
  end

  get :products do
    @title = 'Все товары'

    params.each{ |k, v| params[k] = v&.empty? ? :all : v == 'all' ? :all : v }

    @start_date = params[:s_date].to_date rescue Date.today - 7.days
    @end_date = params[:e_date].to_date rescue Date.today

    town = params[:town] || :all
    client = (params[:client] || :all) == :all ? :all : params[:client].to_i
    manager = (params[:manager] || :all) == :all ? :all : params[:manager].to_i
    section = (params[:section] || :all) == :all ? :all : params[:section].to_i
    delivery = params[:delivery] || :all
    state = (params[:state] || :all).to_sym

    sort = params[:sort] || 'created_at'
    seq = (params[:seq] || :category).to_sym
    seq = [:ap_sum, :arch_amount, :amount, :stick_amount, :done_amount, :price, :p_dn].include?(seq) ? seq : :category

    search_list = (params[:search] || '').downcase.split(/[\s,.'"()-]/).compact
    dir = !params[:sort] && !params[:dir] ? 'desc' : params[:dir] || 'asc'

    date_sel = (params[:date_sel] || :created_at).to_sym
    date_sel = [:created_at, :send, :done].include?(date_sel) ? date_sel : :created_at

    page_size = (params[:page_size] || 50).to_i
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1

    @load_orders = params[:load_orders] == '1' || params[:export] == '1'
    # params[:load_orders] = nil

    @path = []
    @path += params[:path]&.to_s&.split('_') || [] if params[:path] != :all

    orders_query = Order.where('status > ?', Order.statuses[:draft])
    orders_query = orders_query.where("#{ date_sel } < ?", @end_date + 1.day).where("#{ date_sel } > ?", @start_date) if date_sel == :created_at

    @orders = orders_query.includes(:client).order(sort => dir).to_a

    if date_sel == :send
      @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i).map{ |k, v| [k, timeline_unf(v)] }.to_h
      @orders.select! do |o|
        odate = @kc_timelines[o.id]
        next false if odate.nil?
        odate > @start_date && odate < @end_date
      end
    elsif date_sel == :done
      @kc_done = CabiePio.all_keys(@orders.map(&:id), folder: [:stock, :order, :done]).flat.trans(:to_i).map{ |k, v| [k, v.to_datetime] }.to_h
      @orders.select! do |o|
        odate = @kc_done[o.id]
        next false if odate.nil?
        odate > @start_date && odate < @end_date
      end
    end

    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)

    @orders.select!{ |o| @kc_towns[@kc_orders[o.id.to_s]]&.key&.public == town } if town != :all

    @clients_list = @orders.map{ |o| o.client }.compact.uniq
    @managers_list = @clients_list.map{ |c| c&.manager }.compact.uniq

    @orders.select!{ |o| o.client_id == client } if client != :all
    @orders.select!{ |o| o.client&.manager&.id == manager } if manager != :all
    @orders.select!{ |o| o.delivery == delivery } if delivery != :all

    @kc_os = KSM::OrderStatus.find_all(@orders.map(&:id))
    @kc_os_hash = @kc_os.map{ |kc| [kc.id.to_i, kc] }.to_h
    @orders.select!{ |o| @kc_os_hash[o.id].state == state } if state != :all
    @orders.select!{ |o| @kc_os_hash[o.id].state(section) != :none } if section != :all


    have_orders = @orders.size > 0
    @orders_count = @orders.size

    @sections = KSM::Section.all.sort_by(&:ix)
    @states_list = [:anew, :prepare, :current, :finished, :shipped, :canceled]
    @delivery_list = Order.deliveries.map{ |d, id| d }
    @category_list = SL::Category.all

    section_id = @sections.detect{ |s| s.ix == section }&.id
    pec = 0
    if @category_list.detect{ |c| c.id == @path.first }&.section_id == section_id
      pec = 1
      if @path.size >= 2
        @path.each_cons(2) do |p1, p2|
          pec += 1 if @category_list.detect{ |c| c.id == p2 }&.category_id == p1
        end
      end
    end

    @path = @path.first(pec)
    @path.prepend(section_id) if section != :all
    @path.map!{ |p| [p, get_category_childs(p).sort_by(&:name)] } if @path.size > 0
    10.times do
      pll = @path.last[1]
      break if pll.size != 1
      @path << [pll.last.id, get_category_childs(pll.last.id)]
    end if @path.size > 0
    cat_show_list = get_category_all_childs(@path.last[0]) if @path.size > 0

    no_search = search_list.size == 0
    data_table = []
    if @load_orders
      @orders.each do |ord|
        ord.order_lines.each do |ol|
          ol_p = ol.product
          p_cat_id = ol_p.category_id
          p_dn = ol_p.displayname
          name_words = no_search ? [] : p_dn.downcase.split(/[\s,.'"()-]/).compact
          if (cat_show_list.nil? || cat_show_list.include?(p_cat_id)) && (no_search || search_list.all?{ |w| name_words.include?(w) })
            data_table << OrderLineData.new(ord, ol, p_dn, p_cat_id)
          end
        end
      end

      @orders = data_table.map(&:ord).uniq.sort_by(&:id)
    elsif @path.size > 1 || !no_search
      @orders.select! do |ord|
        ord.order_lines.any? do |ol|
          ol_p = ol.product
          name_words = no_search ? [] : ol_p.displayname.downcase.split(/[\s,.'"()-]/).compact
          (cat_show_list.nil? || cat_show_list.include?(ol_p.category_id)) && (no_search || search_list.all?{ |w| name_words.include?(w) })
        end
      end
    end

    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat if have_orders
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq) if have_orders
    @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }
    @clients_list = @orders.map{ |o| o.client }.uniq.compact if have_orders
    @managers_list = @clients_list.map{ |c| c&.manager }.uniq.compact if have_orders

    @oc_clients = Hash.new(0)
    @oc_managers = Hash.new(0)
    @oc_towns = Hash.new(0)

    @orders.each do |o|
      oc = o.client
      @oc_towns[@kc_towns[@kc_orders[o.id.to_s]]&.key&.public] += 1
      @oc_clients[oc.id] += 1
      @oc_managers[oc&.manager&.id] += 1
    end

    @towns_list.sort_by!{ |i, n| [-@oc_towns[i], n] }
    @clients_list.sort_by!{ |c| [-@oc_clients[c.id], c.name] }
    @managers_list.sort_by!{ |m| [-@oc_managers[m.id], m.name] }

    @olstickers = CabiePio.all_keys(data_table.map(&:ol_id), folder: [:m, :order_lines, :sticker_sum]).flat
    data_table.each{ |dt| dt.stick_amount = (@olstickers[dt.ol_id]&.fetch(:v) || 0) }

    if params[:gp]
      @archetypes = KSM::Archetype.all.map{ |a| [a.id, a] }.to_h
      @kc_archs = CabiePio.folder(:product, :archetype).flat
      @kc_archs_m = CabiePio.folder([:product, :archetype_multi]).flat
      # parchs = data_table.map{ |dt|archetype_order(@kc_archs[dt.p_id], dt.ol_id, dt.ord_id) }
      # @rese = CabiePio.all_keys(parchs, folder: [:need, :order]).flat.map{ |k, v|[k.split('_')[1].to_i, v.to_i] }.to_h
      data_table.each do |dt|
        dt.multiply = (@kc_archs_m[dt.p_id] || 1).to_i
        # dt.arch_amount = @rese.fetch(dt.ol_id.to_i, 0)
      end

      @data_table_p_id = data_table.group_by(&:p_id).to_a
      @data_table_p_id_archs = @data_table_p_id.group_by{ |p_id, dt| @kc_archs[p_id] }.to_a

      case seq
      when :category
        @data_table_p_id_archs.sort_by! do |arch_id, dtpi| [
            @sections.detect{ |s|@category_list.detect{ |c|c.id==dtpi.last.last.first.cat_id }&.section_id }.ix,
            dtpi.last.last.first.cat_id,
            (@archetypes[arch_id]&.name || 'Не найдено')
          ]
        end
      when :p_dn
        @data_table_p_id_archs.sort_by!{ |arch_id, dtpi| @archetypes[arch_id]&.name }
      else
        seq = :multi_amount if seq == :amount
        @data_table_p_id_archs.sort_by!{ |arch_id, dtpi| dtpi.map{ |p_id, dts| dts.sum(&seq) }.sum }.reverse!
      end
    else
      seq = :category if seq == :arch_amount
      @data_table_p_id = data_table.group_by(&:p_id).to_a
      case seq
      when :category
        @data_table_p_id.sort_by! do |p_id, dts| [
            @sections.detect{ |s| @category_list.detect{ |c| c.id==dts.first.cat_id }&.section_id }.ix,
            dts.first.cat_id,
            dts.first.p_dn.delete('☠️ ')
          ]
        end
      when :price
        @data_table_p_id.sort_by!{ |p_id, dts| dts.first.price }.reverse!
      when :p_dn
        @data_table_p_id.sort_by!{ |p_id, dts| dts.first.p_dn.delete('☠️ ') }
      else
        @data_table_p_id.sort_by!{ |p_id, dts| dts.sum(&seq) }.reverse!
      end
    end

    @r = url(:reports, :products)
    @ra = [:reports, :products]
    @rah = { deli: params[:deli] } if params[:deli]

    if params[:export]
      fname = "Товары #{ @start_date.strftime('%d.%m.%Y') }-#{ @end_date.strftime('%d.%m.%Y') }.csv"
      headers['Content-Disposition'] = "attachment; filename=#{ fname }"
      output = ''
      output = "\xEF\xBB\xBF" if params.include? :win
      output << CSV.generate(col_sep: ';') do |csv|
        products_print_prepare(!params[:gp].nil?, params[:col]).each do |item|
          csv << item
        end
      end
    else
      render 'reports/products'
    end
  end

  post :products do
    path = category_path_parse(params[:category] || {})
    redirect url(:reports, :products) unless params[:reset_button].nil?
    usable = [:town, :client, :manager, :section, :delivery, :state, :date_sel, :sort, :seq, :gp, :col, :search]
    params_hash = Hash.new
    params.each{ |k, v| params[k] = v&.empty? ? :all : v == 'all' ? :all : v }

    params[:end_date] = params[:start_date] if (params[:start_date].to_date > params[:end_date].to_date)

    usable.each { |i| params_hash[i] = params[i].empty? ? :all : params[i] if !params[i].nil? && params[i] != :all }
    if params[:reset_button].nil?
      params_hash[:s_date] = params[:start_date]
      params_hash[:e_date] = params[:end_date]
    end
    params_hash[:load_orders] = 1 if params[:load_orders_button]

    params_hash[:seq] = nil if params[:seq] == 'done' && params[:date_sel] != 'done'
    params_hash[:path] = path.join('_')

    # params_hash[:changed] = :e if params[:end_date_f] != params[:old_end_date_f]
    # params_hash[:changed] = params_hash[:changed] ? :all : :s if params[:start_date_f] != params[:old_start_date_f]
    redirect url(:reports, :products, params_hash)
  end

  get :orders do
    @title = 'Все заказы'
    @r = url(:reports, :orders)
    @ra = [:reports, :orders]

    params.each{ |k, v| params[k] = v&.empty? ? :all : v == 'all' ? :all : v }

    @start_date = params[:s_date].to_date rescue Date.today - 7.days
    @end_date = params[:e_date].to_date rescue Date.today

    town = params[:town] || :all
    client = (params[:client] || :all) == :all ? :all : params[:client].to_i
    manager = (params[:manager] || :all) == :all ? :all : params[:manager].to_i
    section = (params[:section] || :all) == :all ? :all : params[:section].to_i
    delivery = params[:delivery] || :all
    state = (params[:state] || :all).to_sym
    pay_type = params[:pay_type] || :all

    sort = params[:sort] || 'created_at'
    seq = params[:seq] || ''
    dir = !params[:sort] && !params[:dir] ? 'desc' : params[:dir] || 'asc'

    date_sel = (params[:date_sel] || :created_at).to_sym
    date_sel = [:created_at, :send, :done].include?(date_sel) ? date_sel : :created_at

    page_size = (params[:page_size] || 50).to_i
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1

    @load_orders = params[:load_orders] == '1' || params[:export] == '1'
    params[:load_orders] = nil

    orders_query = Order.where('status > ?', Order.statuses[:draft])
    orders_query = orders_query.where("#{ date_sel } < ?", @end_date + 1.day).where("#{ date_sel } > ?", @start_date) if date_sel == :created_at
    @orders = orders_query.includes(:client).order(sort => dir).to_a

    if date_sel == :send
      @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i).map{ |k, v| [k, timeline_unf(v)] }.to_h
      @orders.select! do |o|
        odate = @kc_timelines[o.id]
        next false if odate.nil?
        odate > @start_date && odate < @end_date
      end
    elsif date_sel == :done
      @kc_done = CabiePio.all_keys(@orders.map(&:id), folder: [:stock, :order, :done]).flat.trans(:to_i).map{ |k, v| [k, v.to_datetime] }.to_h
      @orders.select! do |o|
        odate = @kc_done[o.id]
        next false if odate.nil?
        odate > @start_date && odate < @end_date
      end
    end

    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)

    @orders.select!{ |o| @kc_towns[@kc_orders[o.id.to_s]]&.key&.public == town } if town != :all

    @clients_list = @orders.map{ |o| o.client }.compact.uniq
    managers_ids = @clients_list.map{ |c| c.manager_id }.compact.uniq
    @managers_list = Account.managers.select{ |m| managers_ids.include?(m.id) }

    @orders.select!{ |o| o.client_id == client } if client != :all
    @orders.select!{ |o| o.client.manager_id == manager } if manager != :all
    @orders.select!{ |o| o.delivery == delivery } if delivery != :all

    @kc_os = KSM::OrderStatus.find_all(@orders.map(&:id))
    @kc_os_hash = @kc_os.map{ |kc| [kc.id.to_i, kc] }.to_h
    @orders.select!{ |o| @kc_os_hash[o.id].state == state } if state != :all
    @orders.select!{ |o| @kc_os_hash[o.id].state(section) != :none } if section != :all

    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i)
    @orders.select!{ |o| @kc_cash[o.id] == pay_type } if pay_type != :all

    have_orders = @orders.size > 0

    @sections = KSM::Section.all.sort_by(&:ix)
    @states_list = [:anew, :prepare, :current, :finished, :shipped, :canceled]
    @delivery_list = Order.deliveries.map{ |d, id| d }

    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat if client != :all || manager != :all if have_orders
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq) if client != :all || manager != :all if have_orders
    @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }
    @clients_list = @orders.map{ |o| o.client }.uniq.compact if manager != :all || town != :all if have_orders
    if have_orders && (town != :all || client != :all)
      managers_ids = @clients_list.map{ |c| c.manager_id }.compact.uniq
      @managers_list = Account.managers.select{ |m| managers_ids.include?(m.id) }
    end
    @oc_clients = Hash.new(0)
    @oc_managers = Hash.new(0)
    @oc_towns = Hash.new(0)

    @orders.each do |o|
      oc = o.client
      @oc_towns[@kc_towns[@kc_orders[o.id.to_s]]&.key&.public] += 1
      @oc_clients[oc.id] += 1
      @oc_managers[oc.manager_id] += 1
    end

    @towns_list.sort_by!{ |i, n| [-@oc_towns[i], n] }
    @clients_list.sort_by!{ |c| [-@oc_clients[c.id], c.name] }
    @managers_list.sort_by!{ |m| [-@oc_managers[m.id], m.name] }

    @orders_count = @orders.size

    if @load_orders
      @sections_order_sum = {}
      @deliveries_sum = {}
      @delivery_list.each{ |d| @deliveries_sum[d.to_sym] = [0, 0] }

      @orders.each do |o|
        @sections_order_sum[o.id] = {}
        @sections.each do |s|
          ol_sum = []
          ol_sum_fact = []
          @sections_order_sum[o.id][s.ix]
          o.order_lines.each do |ol|
            pcat = category_matrix[products_hash[ol.product_id]]
            csec = all_catagories.detect{ |c| c.id == pcat }&.section_id
            if csec == s.id
              ol_sum << ol.price * (ol.amount || 0)
              ol_sum_fact << ol.price * (ol.done_amount || 0) unless ol.ignored
            end
          end
          sums = [ol_sum, ol_sum_fact].map(&:sum)
          @sections_order_sum[o.id][s.ix] = sums
          @deliveries_sum[o.delivery.to_sym][0] += sums[0]
          @deliveries_sum[o.delivery.to_sym][1] += sums[1]
        end
      end

      @section_sums = Hash.new(0)
      @section_sums_fact = Hash.new(0)
      @sections_order_sum.each do |id, ord|
        ord.each do |ix, v|
          @section_sums[ix] += v[0]
          @section_sums_fact[ix] += v[1]
        end
      end
    end

    oipmi = @orders.map(&:id)
    @kc_timelines = CabiePio.all_keys(oipmi, folder: [:orders, :timeline]).flat.trans(:to_i).map{ |k, v| [k, timeline_unf(v)] }.to_h if @kc_timelines.nil?
    @kc_done = CabiePio.all_keys(oipmi, folder: [:stock, :order, :done]).flat.trans(:to_i).map{ |k, v| [k, v.to_datetime] }.to_h if @kc_done.nil?

    @orders.sort_by!{ |o| @kc_towns[@kc_orders[o.id.to_s]]&.model&.name || '' } if seq == 'city'
    @orders.sort_by!{ |o| @kc_timelines[o.id] || Time.now } if seq == 'send'
    @orders.sort_by!{ |o| @kc_done[o.id] || Time.now } if seq == 'done'
    @orders.sort_by! do |o|
      odate = @kc_timelines[o.id]
      done_date = @kc_done[o.id]
      odate && done_date ? odate.mjd - done_date.mjd : 999999
    end if seq == 'diff'

    @page_count = (@orders.size / page_size.to_f).ceil
    @page = @page_count if @page > @page_count
    orders_pos = page_size * (@page - 1)
    @orders_in_page = @orders[orders_pos..orders_pos + (page_size - 1)]
    @orders_in_page = [] if @orders_in_page.nil?

    @kc_blinks = CabiePio.all_keys(@orders_in_page.map(&:id), folder: [:orders, :timeline_blink]).flat.trans(:to_i)

    if params[:export]
      fname = "Заказы #{ @start_date.strftime('%d.%m.%Y') }-#{ @end_date.strftime('%d.%m.%Y') }.csv"
      headers['Content-Disposition'] = "attachment; filename=#{ fname }"
      output = ''
      output = "\xEF\xBB\xBF" if params.include? :win
      output << CSV.generate(col_sep: ';') do |csv|
        orders_print_prepare.each do |item|
          csv << item
        end
      end
    else
      render 'reports/orders'
    end
  end

  post :orders do
    redirect url(:reports, :orders) unless params[:reset_button].nil?

    usable = [:town, :client, :manager, :section, :delivery, :state, :date_sel, :page_size, :page, :sort, :seq, :pay_type]
    params_hash = Hash.new
    params.each{ |k, v| params[k] = v&.empty? ? :all : v == 'all' ? :all : v }

    params[:end_date] = params[:start_date] if (params[:start_date].to_date > params[:end_date].to_date)

    usable.each { |i| params_hash[i] = params[i].empty? ? :all : params[i] if !params[i].nil? && params[i] != :all }
    if params[:reset_button].nil?
      params_hash[:s_date] = params[:start_date]
      params_hash[:e_date] = params[:end_date]
    end
    params_hash[:load_orders] = 1 if params[:load_orders_button]

    params_hash[:seq] = nil if params[:seq] == 'done' && params[:date_sel] != 'done'

    # params_hash[:changed] = :e if params[:end_date_f] != params[:old_end_date_f]
    # params_hash[:changed] = params_hash[:changed] ? :all : :s if params[:start_date_f] != params[:old_start_date_f]
    redirect url(:reports, :orders, params_hash)
  end
end