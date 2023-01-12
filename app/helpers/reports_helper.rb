module Fenix::App::ReportsHelper
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