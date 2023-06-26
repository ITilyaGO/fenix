module Fenix::App::ReportsHelper
  def hide_zero_value(number, symbol = nil, inc = 0)
    number.to_i > inc ? number : symbol
  end

  def quotation_marks(value, symbol = '"')
    symbol + value.to_s + symbol
  end

  def dot_to_comma(value, turn_on = true)
    return value unless turn_on
    value.to_s.gsub('.', ',')
  end

  def params_toggle(params, parameter, value, setable = {})
    params.merge({ parameter.to_sym => params[parameter.to_sym].to_s == value.to_s ? nil : value.to_sym }).merge(setable)
  end

  def get_category_childs(cat_id)
    @category_list = SL::Category.all unless @category_list
    @category_list.select{ |c| c.category_id ? c.category_id == cat_id : c.section_id == cat_id }
  end

  def get_category_all_childs(cat_id, endonly = false)
    c_ch = get_category_childs(cat_id).map!(&:id)
    if c_ch.size > 0
      all_ch = []
      c_ch.each do |ch|
        all_ch += get_category_all_childs(ch).map{ |c| [c.first, [cat_id, c.last].join('_')] }
      end
      all_ch << [cat_id, cat_id] unless endonly
      all_ch
    else
      [[cat_id, cat_id]]
    end
  end

  def category_path_parse(path_hash, start = nil)
    arr = [start || path_hash.values.first]
    path_hash.each do
      hn = path_hash[arr.last]
      break if hn.nil?
      arr << hn
    end
    arr
  end

  def select_orders_by_other_dates(date_sel)
    if date_sel == :send
      @kc_timelines = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :timeline]).flat.trans(:to_i).map{ |k, v| [k, timeline_unf(v)] }.to_h
      @orders.select! do |o|
        odate = @kc_timelines[o.id]
        next false if odate.nil?
        odate >= @start_date && odate <= @end_date
      end
    elsif date_sel == :done
      @kc_done = CabiePio.all_keys(@orders.map(&:id), folder: [:stock, :order, :done]).flat.trans(:to_i).map{ |k, v| [k, v.to_datetime] }.to_h
      @orders.select! do |o|
        odate = @kc_done[o.id]
        next false if odate.nil?
        odate >= @start_date && odate <= @end_date
      end
    end
  end

  def get_manager_accounts
    @manager_accounts = Account.managers if @account_managers.nil?
  end

  def managers_list_by_clients_list
    managers_ids = @clients_list.map{ |c| c.manager_id }.compact.uniq
    @managers_list = get_manager_accounts.select{ |m| managers_ids.include?(m.id) }
  end

  def managers_list_by_orders
    managers_ids = @orders.map{ |o| o.client }.uniq.compact.map{ |c| c.manager_id }.compact.uniq
    @managers_list = get_manager_accounts.select{ |m| managers_ids.include?(m.id) }
  end

  def clients_list_by_orders
    @clients_list = @orders.map{ |o| o.client }.uniq.compact
  end

  def kc_os_hash_by_orders
    @kc_os = KSM::OrderStatus.find_all(@orders.map(&:id))
    @kc_os_hash = @kc_os.map{ |kc| [kc.id.to_i, kc] }.to_h
  end

  def calculate_orders_count_in_tcmds(sorting = true, tow: true, cli: true, man: true, del: true, sta: true)
    @oc_towns = Hash.new(0) if tow || @oc_towns.nil?
    @oc_clients = Hash.new(0) if cli || @oc_clients.nil?
    @oc_managers = Hash.new(0) if man || @oc_managers.nil?
    @oc_delivery = Hash.new(0) if del || @oc_delivery.nil?
    @oc_state = Hash.new(0) if sta || @oc_state.nil?

    @orders.each do |o|
      oc = o.client
      @oc_towns[@kc_towns[@kc_orders[o.id.to_s]]&.key&.public] += 1 if tow
      @oc_clients[oc.id] += 1 if cli && oc
      @oc_managers[oc.manager_id] += 1 if man && oc
      @oc_delivery[o.delivery] += 1 if del
      @oc_state[@kc_os_hash[o.id].state] += 1 if sta
    end
    if sorting
      @towns_list.sort_by!{ |i, n| [-@oc_towns[i], n] } if tow
      @clients_list.sort_by!{ |c| [-@oc_clients[c.id], c.name] } if cli
      @managers_list.sort_by!{ |m| [-@oc_managers[m.id], m.name] } if man
    end
  end

  def calculate_orders_count_in_tcmds_inv(sorting = true, tow: false, cli: false, man: false, del: false, sta: false)
    calculate_orders_count_in_tcmds(sorting, tow: tow, cli: cli, man: man, del: del, sta: sta)
  end

def completed_work_print_prepare(excel = false)
    pretty_stat = []

    pretty_stat << ['Наименование', 'Наклеено', 'Цена клейки', 'Сумма клейки', 'Цена продукции', 'Сумма продукции']
    @data_table_p_id.each do |p_id, dts|
      pretty_stat << [
        dts.first.p_dn,
        hide_zero_value(dts.sum(&:stick_amount)),
        dot_to_comma(hide_zero_value(dts.first.stick_price), excel),
        dot_to_comma(hide_zero_value(dts.sum(&:stick_price_sum).round(2)), excel),
        hide_zero_value(dts.first.price),
        dot_to_comma(hide_zero_value(dts.sum(&:stick_sum).round(2)), excel)
      ]
    end

    pretty_stat << [
      'Общая сумма:',
      hide_zero_value(@data_table_p_id.map{ |p_id, dts| dts.sum(&:stick_amount) }.sum),
      nil,
      dot_to_comma(hide_zero_value(@data_table_p_id.map{ |p_id, dts| dts.sum(&:stick_price_sum) }.sum.round(2)), excel),
      nil,
      dot_to_comma(hide_zero_value(@data_table_p_id.map{ |p_id, dts| dts.sum(&:stick_sum) }.sum.round(2)), excel)
    ]
    pretty_stat
  end

  def products_print_prepare(gp, col)
    pretty_stat = []
    orders_head = []
    @orders.each{ |ord| orders_head << ord.id } if col

    if gp
      pretty_stat << ['Наименование', 'Сумма', 'Заказано', 'Наклеено', 'Фактически'] + orders_head

      @data_table_p_id_archs.each do |arch_id, dtpi|
        orders_cells = []

        @orders.each do |ord|
          o_id = ord.id
          ord_dts = []
          dtpi.each{ |p_id, dts| dts.each{ |dt| ord_dts << dt if dt.ord_id == o_id } }
          orders_cells << ((ord_dts.size > 0) ? hide_zero_value(ord_dts&.sum(&:multi_amount)) : nil)
        end if col

        pretty_stat << [
          @archetypes[arch_id]&.name || 'Не найдено',
          hide_zero_value(dtpi.map{ |p_id, dts| dts.sum(&:ap_sum) }.sum),
          hide_zero_value(dtpi.map{ |p_id, dts| dts.sum(&:multi_amount) }.sum),
          hide_zero_value(dtpi.map{ |p_id, dts| dts.sum(&:multi_stick) }.sum),
          hide_zero_value(dtpi.map{ |p_id, dts| dts.sum(&:multi_done) }.sum)
        ] + orders_cells
      end

      pretty_stat << [
        'Общая сумма:',
        @data_table_p_id.map{ |p_id, dts| dts.sum(&:ap_sum) }.sum,
        nil,
        hide_zero_value(@data_table_p_id.map{ |p_id, dts| dts.sum(&:stick_sum) }.sum),
        hide_zero_value(@data_table_p_id.map{ |p_id, dts| dts.sum(&:done_sum) }.sum),
      ]
    else
      pretty_stat << ['Наименование', 'Сумма', 'Цена', 'Заказано', 'Наклеено', 'Фактически'] + orders_head
      @data_table_p_id.each do |p_id, dts|
        orders_cells = []

        @orders.each do |ord|
          o_id = ord.id
          ord_dts = dts.select{ |dt| dt.ord_id == o_id }
          orders_cells << hide_zero_value(ord_dts&.sum(&:amount))
        end if col

        pretty_stat << [
          dts.first.p_dn,
          hide_zero_value(dts.sum(&:ap_sum)),
          hide_zero_value(dts.first.price),
          hide_zero_value(dts.sum(&:amount)),
          hide_zero_value(dts.sum(&:stick_amount)),
          hide_zero_value(dts.sum(&:done_amount))
        ] + orders_cells
      end

      pretty_stat << [
        'Общая сумма:',
        @data_table_p_id.map{ |p_id, dts| dts.sum(&:ap_sum) }.sum,
        nil,
        nil,
        hide_zero_value(@data_table_p_id.map{ |p_id, dts| dts.sum(&:stick_sum) }.sum),
        hide_zero_value(@data_table_p_id.map{ |p_id, dts| dts.sum(&:done_sum) }.sum),
      ]
    end
    pretty_stat
  end

  def orders_print_prepare
    pretty_stat = []
    secs_cols_head = []
    @sections.each do |s|
      secs_cols_head << "#{ s.name[0..2] } С."
      secs_cols_head << "#{ s.name[0..2] } Ф."
    end
    pretty_stat << ['Номер', 'Д.', 'Соз.', 'Отп.', 'Соб.', 'Разн.', 'Город', 'Заказчик', 'Менеджер', 'Статус', 'Сумма', 'Сумма факт.', 'Вып.'] + secs_cols_head
    @orders.each do |order|
      os = @kc_os.detect{ |kc| kc.id.to_i == order.id } || KSM::OrderStatus.new(id: order.id)
      sections_sums = @sections_order_sum[order.id]
      order_sum = sections_sums.map{ |k, v| v[0] }.sum
      order_sum_f = sections_sums.map{ |k, v| v[1] }.sum
      date_format = '%d.%m.%Y'
      odate = @kc_timelines[order.id]
      done_date = @kc_done[order.id]
      diff = odate && done_date ? odate.mjd - done_date.mjd : nil

      secs_cols = []
      @sections.each do |s|
        secs_cols << (sections_sums[s.ix][0] || 0)
        secs_cols << sections_sums[s.ix][1]
      end
      pretty_stat << [
        order.id,
        tja(:delivery, order.delivery),
        order.created_at&.strftime(date_format),
        @kc_timelines[order.id]&.strftime(date_format),
        @kc_done[order.id]&.strftime(date_format),
        diff,
        @kc_towns[@kc_orders[order.id.to_s]]&.model,
        order.client&.name,
        order.client&.manager&.name,
        t(:"status.#{ os.state }"),
        order_sum,
        order_sum_f,
        (order_sum > 0 ? "#{ (order_sum_f / order_sum.to_f * 100).round }%" : "")
      ] + secs_cols
    end
    pretty_stat
  end

  def default_date_list
    {
      created_at: 'Создан',
      send: 'Отправлен',
      done: 'Собран'
    }
  end
end

class OrderLineData
  attr_accessor :ord_id, :ol, :ol_id, :p_id, :p_dn, :cat_id, :cat_path, :price, :amount, :done_amount, :stick_amount, :stick_price, :arch_amount, :multiply, :ignored
  def initialize(ol, p_dn, cat_id, cat_path, stick_amount = 0, arch_amount = 0, multiply = 1)
    @ord_id = ol.order_id
    @ol = ol
    @ol_id = ol.id
    @p_id = ol.product_id
    @p_dn = p_dn
    @cat_id = cat_id
    @cat_path = cat_path
    @price = ol.price
    @amount = ol.amount
    @done_amount = ol.done_amount || 0
    @stick_amount = stick_amount
    @stick_price = 0
    @arch_amount = arch_amount
    @multiply = multiply
    @ignored = ol.ignored
  end

  def ap_sum
    @amount * @price
  end

  def done_sum
    @ignored ? 0 : @done_amount * @price
  end

  def stick_sum
    @stick_amount * @price
  end

  def stick_price_sum
    @stick_price * @stick_amount
  end

  def multi_amount
    @multiply * @amount
  end

  def multi_done
    @ignored ? 0 : @multiply * @done_amount
  end

  def multi_stick
    @multiply * @stick_amount
  end
end