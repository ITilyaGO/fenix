module Fenix::App::ReportsHelper

  def hide_zero_value(number, symbol = nil, inc = 0)
    number.to_i > inc ? number : symbol
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

  def products_print_prepare(gp, col)
    pretty_stat = []
    orders_head = []
    @orders.each{ |ord| orders_head << ord.id } if col == 'orders'

    if gp
      pretty_stat << ['Наименование', 'Сумма', 'Заказано', 'Наклеено', 'Фактически'] + orders_head

      @data_table_p_id_archs.each do |arch_id, dtpi|
        orders_cells = []

        @orders.each do |ord|
          o_id = ord.id
          ord_dts = []
          dtpi.each{ |p_id, dts| dts.each{ |dt| ord_dts << dt if dt.ord_id == o_id } }
          orders_cells << ((ord_dts.size > 0) ? hide_zero_value(ord_dts&.sum(&:multi_amount)) : nil)
        end if col == 'orders'

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
        end if col == 'orders'

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
end

class OrderLineData
  attr_accessor :ord, :ord_id, :ol, :ol_id, :p_id, :p_dn, :cat_id, :cat_path, :price, :amount, :done_amount, :stick_amount, :arch_amount, :multiply, :ignored
  def initialize(ord, ol, p_dn, cat_id, cat_path, stick_amount = 0, arch_amount = 0, multiply = 1)
    @ord = ord
    @ord_id = ord.id
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