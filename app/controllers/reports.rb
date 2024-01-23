Fenix::App.controllers :reports do
  get :index do
    render 'reports/index'
  end

  get :products do
    @title = 'Все товары'
    @start_date = Date.today - 7.days
    @end_date = Date.today
    @page = 1
    @load_orders = false
    @path = []
    @btn_memory = {}
    params[:start_date] = @start_date
    params[:end_date] = @end_date
    params[:date_sel] = :created_at

    orders_query = Order.where('status > ?', Order.statuses[:draft])
    orders_query = orders_query.where("#{ :created_at } <= ?", @end_date + 1.day).where("#{ :created_at } >= ?", @start_date)
    @orders = orders_query.includes(:client).to_a

    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)
    @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }
    kc_os_hash_by_orders
    clients_list_by_orders
    managers_list_by_clients_list
    calculate_orders_count_in_tcmds

    @date_list = default_date_list

    @sections = KSM::Section.all.sort_by(&:ix)
    @states_list = KSM::OrderStatus::BIT_STATES.keys

    @delivery_list = Order.deliveries.map{ |d, id| d }
    @category_list = SL::Category.all

    @orders_count = @orders.size
    @data_table_p_id = []
    @data_table_p_id_archs = []

    @r = url(:reports, :products)
    @ra = [:reports, :products]
    render 'reports/products'
  end

  post :products do
    redirect url(:reports, :products) unless params[:reset_button].nil?
    path = category_path_parse(params[:category] || {})

    @btn_memory = {}
    params[:btn_memory]&.each{ |k, v| @btn_memory[k.to_sym] = (v == 'false' || v&.empty?) ? nil : v }
    params[:btn]&.each{ |k, v| @btn_memory[k.to_sym] = (v == 'false' || v&.empty?) ? nil : v }

    params.each{ |k, v| params[k] = v&.empty? ? nil : v == 'all' ? nil : v }
    params.compact!
    @start_date = params[:start_date].to_date rescue Date.today - 7.days
    @end_date = params[:end_date].to_date rescue Date.today
    @end_date = @start_date if @start_date > @end_date

    towns = params[:town]&.split('_')
    clients = params[:client]&.split('_')&.map(&:to_i)
    managers = params[:manager]&.split('_')&.map(&:to_i)
    section = params[:section]&.to_i
    deliverys = params[:delivery]&.split('_')
    state = params[:state]&.to_sym

    sort = params[:sort] || 'created_at'
    seq = (@btn_memory[:seq] || :category).to_sym
    seq = [:ap_sum, :arch_amount, :amount, :stick_amount, :done_amount, :price, :p_dn].include?(seq) ? seq : :category

    search_list = split_for_search(params[:search] || '')
    no_search = search_list.size == 0

    dir = !params[:sort] && !params[:dir] ? 'desc' : params[:dir] || 'asc'

    date_sel = (params[:date_sel] || :created_at).to_sym
    date_sel = default_date_list.keys.include?(date_sel) ? date_sel : :created_at

    page_size = (params[:page_size] || 50).to_i
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1

    @load_orders = params[:load_orders_button] || params[:export] || params[:export_win] || params[:btn]

    @path = params[:category] ? category_path_parse(params[:category]) - ['all'] : []
    @old_path_string = @path.join('_')
    @old_path = (params[:old_path] || '').split('_')

    @filtred_orders = (params[:filtred_orders] || '').split('_')

    params[:category]&.each{ |k, v| params[:category][k] = nil if v&.empty? }
    params[:category]&.compact!
    old_params = params[:old] || {}
    filter_change_list = []
    old_params.each{ |k, v| filter_change_list << k if params[k].to_s != v }
    filter_change_list << :category unless (@old_path - @path).empty?
    cat_any_change = @path != @old_path || old_params[:search] != params[:search]


    changed_filter = filter_change_list.size != 0

    if (changed_filter)
      orders_query = Order.where('status > ?', Order.statuses[:draft]) if state != :draft
      orders_query = Order.all.includes(:client, :place, :order_parts).where("status = ?", Order.statuses[:draft]) if state == :draft
      orders_query = orders_query.where("#{ date_sel } <= ?", @end_date + 1.day).where("#{ date_sel } >= ?", @start_date) if date_sel == :created_at
    else
      orders_query = Order.where(id: @filtred_orders)
    end
    @orders = orders_query.includes(:client).order(sort => dir).to_a

    select_orders_by_other_dates(date_sel)

    @orders.select!{ |o| deliverys.include?(o.delivery) } if deliverys

    kc_os_hash_by_orders
    filter_orders_by_section_state(section, state)


    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)
    @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }

    clients_list_by_orders
    managers_list_by_clients_list
    calculate_orders_count_in_tcmds(section: section)

    @orders.select!{ |o| clients.include?(o.client_id) } if clients
    @orders.select!{ |o| towns.include?(@kc_towns[@kc_orders[o.id.to_s]]&.key&.public) } if towns
    @orders.select!{ |o| managers.include?(o.client&.manager_id) } if managers


    have_orders = @orders.size > 0
    @orders_count = @orders.size

    @date_list = default_date_list

    @sections = KSM::Section.all.sort_by(&:ix)
    @states_list = KSM::OrderStatus::BIT_STATES.keys

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
    @path.prepend(section_id) if section
    @path.map!{ |p| [p, get_category_childs(p).sort_by(&:name)] } if @path.size > 0
    10.times do
      pll = @path.last[1]
      break if pll.size != 1
      @path << [pll.last.id, get_category_childs(pll.last.id)]
    end if @path.size > 0

    cat_show_list = []
    if @path.size > 0
      cat_show_list = get_category_all_childs(@path.last[0])
    elsif @load_orders
      @sections.each { |s| cat_show_list += get_category_all_childs(s.id) }
    end

    cat_show_list = cat_show_list.to_h
    cat_show_list_empty = cat_show_list.empty?

    data_table = []
    is_cat_filter = ((changed_filter || cat_any_change) && (@path.size > 1 || !no_search)) || state == :draft
    if @load_orders || is_cat_filter
      ksm_orders = KSM::Order.find_all(@orders.map(&:id))
      lines_ids = ksm_orders.map(&:lines).flatten
      orders_lines = KSM::OrderLine.find_all(lines_ids).reject(&:del)
      products_ids = orders_lines.map(&:product_id).uniq
      products = Product.find_all(products_ids)
      products_h = products.map{ |p| [p.id, p] }.to_h
      products_dn = products.map{ |p| [p.id, p.displayname] }.to_h if @load_orders || !no_search
    end
    if @load_orders
      orders_lines.each do |ol|
        ol_p = products_h[ol.product_id]
        p_cat_id = ol_p.category_id
        p_dn = products_dn[ol.product_id]
        name_words = split_for_search(p_dn) unless no_search
        cat_path = cat_show_list[p_cat_id]
        if (cat_show_list_empty || !cat_path.nil?) && (no_search || search_list.all?{ |w| name_words.include?(w) })
          data_table << OrderLineData.new(ol, p_dn, p_cat_id, cat_path || '')
        end
      end

      orders_ids = data_table.map(&:ord_id).uniq
      @orders.select!{ |o| orders_ids.include?(o.id) }
    elsif is_cat_filter
      grouped_orders_lines = orders_lines.group_by(&:order_id)
      @orders.select! do |ord|
        ols = grouped_orders_lines[ord.id]
        ols&.any? do |ol|
          ol_p = products_h[ol.product_id]
          name_words = split_for_search(products_dn[ol.product_id]) unless no_search
          (cat_show_list_empty || cat_show_list[ol_p.category_id]) && (no_search || search_list.all?{ |w| name_words.include?(w) })
        end
      end
    end

    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat if have_orders
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq) if have_orders
    if (@path.size > 1 || !no_search)
      @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }
      clients_list_by_orders
      managers_list_by_clients_list
      calculate_orders_count_in_tcmds(section: section)
    else
      @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] } if managers || clients
      clients_list_by_orders if have_orders && (towns || managers)
      managers_list_by_clients_list if towns || clients
      calculate_orders_count_in_tcmds(man: (towns || clients), cli: (towns || managers), tow: (clients || managers), section: section)
    end

    @olstickers = CabiePio.all_keys(data_table.map(&:ol_id), folder: [:m, :order_lines, :sticker_sum]).flat
    data_table.each{ |dt| dt.stick_amount = (@olstickers[dt.ol_id]&.fetch(:v) || 0) }

    if @btn_memory[:gp]
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
            dtpi.last.last.first.cat_path,
            (@archetypes[arch_id]&.name || 'Не найдено')
          ]
        end
      when :p_dn
        @data_table_p_id_archs.sort_by!{ |arch_id, dtpi| @archetypes[arch_id]&.name || '' }
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
            dts.first.cat_path.downcase,
            dts.first.p_dn.delete('☠️ ').downcase
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

    @title = 'Все товары'
    @r = url(:reports, :products)
    @ra = [:reports, :products]
    @rah = { deli: params[:deli] } if params[:deli]
    if (params[:export] || params[:export_win])
      fname = "Товары #{ @start_date.strftime('%d.%m.%Y') }-#{ @end_date.strftime('%d.%m.%Y') }.csv"
      headers['Content-Disposition'] = "attachment; filename=#{ fname }"
      output = ''
      output = "\xEF\xBB\xBF" if params[:export_win]
      output << CSV.generate(col_sep: ';') do |csv|
        products_print_prepare(@btn_memory[:gp], @btn_memory[:col]).each do |item|
          csv << item
        end
      end
    else
      render 'reports/products'
    end
  end

  get :orders do
    @start_date = Date.today - 7.days
    @end_date = Date.today
    @page = 1
    @load_orders = false
    @btn_memory = {}
    params[:start_date] = @start_date
    params[:end_date] = @end_date

    orders_query = Order.where('status > ?', Order.statuses[:draft])
    orders_query = orders_query.where("#{ :created_at } <= ?", @end_date + 1.day).where("#{ :created_at } >= ?", @start_date)
    @orders = orders_query.includes(:client).to_a

    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i)
    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)
    @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }
    kc_os_hash_by_orders
    clients_list_by_orders
    managers_list_by_clients_list
    calculate_orders_count_in_tcmds

    @page = 1
    @page_count = (@orders.size / 50).ceil
    @page = @page_count if @page > @page_count
    @orders_in_page = @orders[0..50]

    @date_list = default_date_list

    @sections = KSM::Section.all.sort_by(&:ix)
    @states_list = KSM::OrderStatus::BIT_STATES.keys

    @delivery_list = Order.deliveries.map{ |d, id| d }
    @category_list = SL::Category.all

    @title = 'Все заказы'
    @r = url(:reports, :orders)
    @ra = [:reports, :orders]
    render 'reports/orders'
  end

  post :orders do
    redirect url(:reports, :orders) unless params[:reset_button].nil?

    @title = 'Все заказы'

    @btn_memory = {}
    params[:btn_memory]&.each{ |k, v| @btn_memory[k.to_sym] = (v == 'false' || v&.empty?) ? nil : v }
    params[:btn]&.each{ |k, v| @btn_memory[k.to_sym] = (v == 'false' || v&.empty?) ? nil : v }

    params.each{ |k, v| params[k] = v&.empty? ? nil : v == 'all' ? nil : v }
    params.compact!
    @start_date = params[:start_date].to_date rescue Date.today - 7.days
    @end_date = params[:end_date].to_date rescue Date.today
    @end_date = @start_date if @start_date > @end_date

    towns = params[:town]&.split('_')
    clients = params[:client]&.split('_')&.map(&:to_i)
    managers = params[:manager]&.split('_')&.map(&:to_i)
    section = params[:section]&.to_i
    deliverys = params[:delivery]&.split('_')
    state = params[:state]&.to_sym

    pay_type = @btn_memory[:pay_type]
    params[:pay_type] = pay_type

    seq = (@btn_memory[:seq] || :category).to_sym
    seq = (default_date_list.keys + [:diff, :city]).include?(seq) ? seq : :none
    dir = seq == :created_at ? 'asc' : 'desc'
    date_sel = (params[:date_sel] || :created_at).to_sym
    date_sel = default_date_list.keys.include?(date_sel) ? date_sel : :created_at

    page_size = (params[:page_size] || 50).to_i
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1

    @load_orders = params[:load_orders_button] || params[:export] || params[:export_win]
    @btn_memory[:load_orders_button] = nil

    old_params = params[:old] || {}

    orders_query = Order.where('status > ?', Order.statuses[:draft]) if state != :draft
    orders_query = Order.all.includes(:client, :place, :order_parts).where("status = ?", Order.statuses[:draft]) if state == :draft
    orders_query = orders_query.where("#{ date_sel } <= ?", @end_date + 1.day).where("#{ date_sel } >= ?", @start_date) if date_sel == :created_at
    @orders = orders_query.includes(:client).order('created_at' => dir).to_a

    select_orders_by_other_dates(date_sel)

    kc_os_hash_by_orders
    
    filter_orders_by_section_state(section, state)


    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)
    @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }

    clients_list_by_orders
    managers_list_by_clients_list

    calculate_orders_count_in_tcmds_inv(man: true)  
    @orders.select!{ |o| managers.include?(o.client&.manager_id) } if managers

    calculate_orders_count_in_tcmds_inv(tow: true)
    @orders.select!{ |o| towns.include?(@kc_towns[@kc_orders[o.id.to_s]]&.key&.public) } if towns

    calculate_orders_count_in_tcmds_inv(cli: true)
    @orders.select!{ |o| clients.include?(o.client_id) } if clients

    calculate_orders_count_in_tcmds_inv(del: true)
    @orders.select!{ |o| deliverys.include?(o.delivery) } if deliverys

    calculate_orders_count_in_tcmds_inv(sta: true, section: section)

    @kc_cash = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :cash]).flat.trans(:to_i)
    @orders.select!{ |o| @kc_cash[o.id] == pay_type } if pay_type

    have_orders = @orders.size > 0
    @orders_count = @orders.size

    @date_list = default_date_list

    @sections = KSM::Section.all.sort_by(&:ix)
    @states_list = KSM::OrderStatus::BIT_STATES.keys

    @delivery_list = Order.deliveries.map{ |d, id| d }
    @category_list = SL::Category.all

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
    @kc_anew = CabiePio.all_keys(oipmi, folder: [:orders, :anewdate]).flat.trans(:to_i).map{ |k, v| [k, timeline_unf(v)] }.to_h if @kc_anew.nil?

    @orders.sort_by!{ |o| @kc_towns[@kc_orders[o.id.to_s]]&.model&.name || '' } if seq == :city
    @orders.sort_by!{ |o| @kc_timelines[o.id] || Time.now } if seq == :send
    @orders.sort_by!{ |o| @kc_done[o.id] || Time.now } if seq == :done
    @orders.sort_by!{ |o| @kc_anew[o.id] || Time.now } if seq == :anew
    @orders.sort_by! do |o|
      odate = @kc_timelines[o.id]
      done_date = @kc_done[o.id]
      odate && done_date ? odate.mjd - done_date.mjd : 999999
    end if seq == :diff

    @page_count = (@orders.size / page_size.to_f).ceil
    @page = @page_count if @page > @page_count
    orders_pos = page_size * (@page - 1)
    @orders_in_page = @orders[orders_pos..orders_pos + (page_size - 1)]
    @orders_in_page = [] if @orders_in_page.nil?

    @kc_blinks = CabiePio.all_keys(@orders_in_page.map(&:id), folder: [:orders, :timeline_blink]).flat.trans(:to_i)

    @r = url(:reports, :orders)
    @ra = [:reports, :orders]
    if (params[:export] || params[:export_win])
      fname = "Заказы #{ @start_date.strftime('%d.%m.%Y') }-#{ @end_date.strftime('%d.%m.%Y') }.csv"
      headers['Content-Disposition'] = "attachment; filename=#{ fname }"
      output = ''
      output = "\xEF\xBB\xBF" if params[:export_win]
      output << CSV.generate(col_sep: ';') do |csv|
        orders_print_prepare.each do |item|
          csv << item
        end
      end
    else
      render 'reports/orders'
    end
  end

  get :completed_work do
    @title = 'Клейка продуктов'
    @start_date = Date.today - 7.days
    @end_date = Date.today
    @page = 1
    @load_orders = false
    @path = []
    @btn_memory = {}
    params[:start_date] = @start_date
    params[:end_date] = @end_date
    params[:date_sel] = :created_at

    orders_query = Order.where('status > ?', Order.statuses[:draft])
    orders_query = orders_query.where("#{ :created_at } <= ?", @end_date + 1.day).where("#{ :created_at } >= ?", @start_date)
    @orders = orders_query.includes(:client).to_a

    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)
    @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }
    kc_os_hash_by_orders
    clients_list_by_orders
    managers_list_by_clients_list
    calculate_orders_count_in_tcmds

    @date_list = {created_at: 'Создан'}

    @sections = KSM::Section.all.sort_by(&:ix)
    @states_list = KSM::OrderStatus::BIT_STATES.keys

    @delivery_list = Order.deliveries.map{ |d, id| d }
    @category_list = SL::Category.all

    @orders_count = @orders.size
    @data_table_p_id = []
    @data_table_p_id_archs = []

    @r = url(:reports, :completed_work)
    @ra = [:reports, :completed_work]
    render 'reports/completed_work'
  end

  post :completed_work do
    redirect url(:reports, :completed_work) unless params[:reset_button].nil?
    path = category_path_parse(params[:category] || {})

    @btn_memory = {}
    params[:btn_memory]&.each{ |k, v| @btn_memory[k.to_sym] = (v == 'false' || v&.empty?) ? nil : v }
    params[:btn]&.each{ |k, v| @btn_memory[k.to_sym] = (v == 'false' || v&.empty?) ? nil : v }

    params.each{ |k, v| params[k] = v&.empty? ? nil : v == 'all' ? nil : v }
    params.compact!
    @start_date = params[:start_date].to_date rescue Date.today - 7.days
    @end_date = params[:end_date].to_date rescue Date.today
    @end_date = @start_date if @start_date > @end_date

    towns = params[:town]&.split('_')
    clients = params[:client]&.split('_')&.map(&:to_i)
    managers = params[:manager]&.split('_')&.map(&:to_i)
    section = params[:section]&.to_i
    deliverys = params[:delivery]&.split('_')
    state = params[:state]&.to_sym

    sort = params[:sort] || 'created_at'
    seq = (@btn_memory[:seq] || :category).to_sym
    seq = [:ap_sum, :arch_amount, :amount, :stick_price, :stick_amount, :stick_sum, :stick_price_sum, :done_amount, :price, :p_dn].include?(seq) ? seq : :category
    search_list = split_for_search(params[:search] || '')
    no_search = search_list.size == 0

    dir = !params[:sort] && !params[:dir] ? 'desc' : params[:dir] || 'asc'

    date_sel = (params[:date_sel] || :created_at).to_sym
    date_sel = default_date_list.keys.include?(date_sel) ? date_sel : :created_at

    page_size = (params[:page_size] || 50).to_i
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1

    @load_orders = params[:load_orders_button] || params[:export] || params[:export_win] || params[:btn]

    @path = params[:category] ? category_path_parse(params[:category]) - ['all'] : []
    @old_path_string = @path.join('_')
    @old_path = (params[:old_path] || '').split('_')

    @filtred_orders = (params[:filtred_orders] || '').split('_')

    params[:category]&.each{ |k, v| params[:category][k] = nil if v&.empty? }
    params[:category]&.compact!
    old_params = params[:old] || {}
    filter_change_list = []
    old_params.each{ |k, v| filter_change_list << k if params[k].to_s != v }
    filter_change_list << :category unless (@old_path - @path).empty?
    cat_any_change = @path != @old_path || old_params[:search] != params[:search]


    changed_filter = filter_change_list.size != 0

    if (changed_filter)
      orders_query = Order.where('status > ?', Order.statuses[:draft]) if state != :draft
      orders_query = Order.all.includes(:client, :place, :order_parts).where("status = ?", Order.statuses[:draft]) if state == :draft
      # orders_query = orders_query.where("#{ date_sel } <= ?", @end_date + 1.day).where("#{ date_sel } >= ?", @start_date)
    else
      orders_query = Order.where(id: @filtred_orders)
    end
    @orders = orders_query.includes(:client).order(sort => dir).to_a
    @kc_done = CabiePio.all_keys(@orders.map(&:id), folder: [:stock, :order, :done]).flat.trans(:to_i).map{ |k, v| [k, v.to_datetime] }.to_h
    @orders.select! do |o|
      o_created_at = o.created_at.to_date
      next true if o_created_at >= @start_date && o_created_at <= @end_date
      o_done = @kc_done[o.id]
      !o_done.nil? && (o_done >= @start_date && o_done <= @end_date)
    end
    # select_orders_by_other_dates(date_sel)

    @orders.select!{ |o| deliverys.include?(o.delivery) } if deliverys

    kc_os_hash_by_orders
    filter_orders_by_section_state(section, state)

  
    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq)
    @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }

    clients_list_by_orders
    managers_list_by_clients_list
    calculate_orders_count_in_tcmds(section: section)

    @orders.select!{ |o| clients.include?(o.client_id) } if clients
    @orders.select!{ |o| towns.include?(@kc_towns[@kc_orders[o.id.to_s]]&.key&.public) } if towns
    @orders.select!{ |o| managers.include?(o.client&.manager_id) } if managers


    have_orders = @orders.size > 0
    @orders_count = @orders.size

    @date_list = { created_at: 'Наклеен' }

    @sections = KSM::Section.all.sort_by(&:ix)
    @states_list = KSM::OrderStatus::BIT_STATES.keys

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
    @path.prepend(section_id) if section
    @path.map!{ |p| [p, get_category_childs(p).sort_by(&:name)] } if @path.size > 0
    10.times do
      pll = @path.last[1]
      break if pll.size != 1
      @path << [pll.last.id, get_category_childs(pll.last.id)]
    end if @path.size > 0

    cat_show_list = []
    if @path.size > 0
      cat_show_list = get_category_all_childs(@path.last[0])
    elsif @load_orders
      @sections.each { |s| cat_show_list += get_category_all_childs(s.id) }
    end

    cat_show_list = cat_show_list.to_h
    cat_show_list_empty = cat_show_list.empty?

    data_table = []
    is_cat_filter = ((changed_filter || cat_any_change) && (@path.size > 1 || !no_search)) || state == :draft
    if @load_orders || is_cat_filter
      ksm_orders = KSM::Order.find_all(@orders.map(&:id))
      lines_ids = ksm_orders.map(&:lines).flatten
      orders_lines = KSM::OrderLine.find_all(lines_ids).reject(&:del)
      products_ids = orders_lines.map(&:product_id).uniq
      products = Product.find_all(products_ids)
      products_h = products.map{ |p| [p.id, p] }.to_h
      products_dn = products.map{ |p| [p.id, p.displayname] }.to_h if @load_orders || !no_search
    end

    if @load_orders
      @olstickers = CabiePio.all_keys(orders_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum]).flat
      orders_lines.each do |ol|
        ol_p = products_h[ol.product_id]
        p_cat_id = ol_p.category_id
        p_dn = products_dn[ol.product_id]
        name_words = split_for_search(p_dn) unless no_search
        cat_path = cat_show_list[p_cat_id]
        olsticker_t_val = @olstickers.fetch(ol.id, nil)&.fetch(:t, nil)
        olsticker_date = olsticker_t_val.nil? ? nil : timeline_unf(olsticker_t_val)
        if (cat_show_list_empty || !cat_path.nil?) && 
          (!olsticker_date.nil? && (olsticker_date >= @start_date && olsticker_date <= @end_date)) && 
          (no_search || search_list.all?{ |w| name_words.include?(w) })
          data_table << OrderLineData.new(ol, p_dn, p_cat_id, cat_path || '')
        end
      end

      orders_ids = data_table.map(&:ord_id).uniq
      @orders.select!{ |o| orders_ids.include?(o.id) }
    else 
      ksm_orders = KSM::Order.find_all(@orders.map(&:id)) if ksm_orders.nil?
      ksm_orders_hash = ksm_orders.map { |ksm_o| [ksm_o.id.to_i, ksm_o] }.to_h
      @olstickers = CabiePio.all_keys(ksm_orders.map(&:lines).flatten.uniq, folder: [:m, :order_lines, :sticker_sum]).flat
      @orders.select! do |ord|
        ols_ids = ksm_orders_hash[ord.id]&.lines
        ols_ids&.any? do |id|
          olsticker_t_val = @olstickers.fetch(id.to_s, nil)&.fetch(:t, nil)
          olsticker_date = olsticker_t_val.nil? ? nil : timeline_unf(olsticker_t_val)
          (!olsticker_date.nil? && (olsticker_date >= @start_date && olsticker_date <= @end_date))
        end
      end

      if is_cat_filter
        grouped_orders_lines = orders_lines.group_by(&:order_id)
        @orders.select! do |ord|
          ols = grouped_orders_lines[ord.id]
          ols&.any? do |ol|
            ol_p = products_h[ol.product_id]
            name_words = split_for_search(products_dn[ol.product_id]) unless no_search
            (cat_show_list_empty || cat_show_list[ol_p.category_id]) && (no_search || search_list.all?{ |w| name_words.include?(w) })
          end
        end
      end
    end

    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat if have_orders
    @kc_towns = KatoAPI.batch(@kc_orders.values.uniq) if have_orders
    if (@path.size > 1 || !no_search)
      @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] }
      clients_list_by_orders
      managers_list_by_clients_list
      calculate_orders_count_in_tcmds(section: section)
    else
      @towns_list = @kc_towns.map{ |k, v| [k, v&.model.name] } if managers || clients
      clients_list_by_orders if have_orders && (towns || managers)
      managers_list_by_clients_list if towns || clients
      calculate_orders_count_in_tcmds(man: (towns || clients), cli: (towns || managers), tow: (clients || managers), section: section)
    end

    # calculate_orders_count_in_tcmds(section: section)

    @kc_sticker = CabiePio.all_keys(data_table.map(&:p_id).uniq, folder: [:products, :sticker]).flat
    @olstickers = CabiePio.all_keys(data_table.map(&:ol_id), folder: [:m, :order_lines, :sticker_sum]).flat if @olstickers.nil?
    data_table.each do |dt|
      dt.stick_amount = (@olstickers[dt.ol_id]&.fetch(:v) || 0)
      dt.stick_price = @kc_sticker[dt.p_id].to_f || 0
    end

    seq = :category if seq == :arch_amount
    @data_table_p_id = data_table.group_by(&:p_id).to_a
    case seq
    when :category
      @data_table_p_id.sort_by! do |p_id, dts| [
          dts.first.cat_path,
          dts.first.p_dn.delete('☠️ ')
        ]
      end
    when :price
      @data_table_p_id.sort_by!{ |p_id, dts| dts.first.price }.reverse!
    when :p_dn
      @data_table_p_id.sort_by!{ |p_id, dts| dts.first.p_dn.delete('☠️ ') }
    when :stick_price
      @data_table_p_id.sort_by!{ |p_id, dts| dts.first.stick_price }.reverse!
    else
      @data_table_p_id.sort_by!{ |p_id, dts| dts.sum(&seq) }.reverse!
    end

    @title = 'Клейка продуктов'
    @r = url(:reports, :completed_work)
    @ra = [:reports, :completed_work]
    @rah = { deli: params[:deli] } if params[:deli]
    if (params[:export] || params[:export_win])
      fname = "Клейка продуктов #{ @start_date.strftime('%d.%m.%Y') }-#{ @end_date.strftime('%d.%m.%Y') }.csv"
      headers['Content-Disposition'] = "attachment; filename=#{ fname }"
      output = ''
      output = "\xEF\xBB\xBF" if params[:export_win]
      output << CSV.generate(col_sep: ';') do |csv|
        completed_work_print_prepare(params[:export_win]).each do |item|
          csv << item
        end
      end
    else
      render 'reports/completed_work'
    end
  end
end