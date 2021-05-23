module Fenix::App::MigrateHelpers
  def sticker_day_007_up
    orders = CabiePio.folder(:sticker, :order_progress).flat.trans(:to_i).keys
    # ar_orders = Order.find(orders)
    history = CabiePio.all_keys(orders, folder: [:m, :sticker, :order_history]).flat.trans(:to_i)
    orders.each do |order_id|
      or_history = history[order_id].keys.sort.reverse
      ar_order = Order.find order_id
      ol_ids = ar_order.order_lines.map(&:id)
      or_history.each_with_index do |tid, i|
        # break if i == or_history.size
        day = timeline_unf tid
        ol_ids.each do |ol|
          s2 = CabiePio.get([:m, :order_lines, :sticker], "#{ol}_#{tid}").data[:v] rescue nil
          next unless s2
          s1 = CabiePio.get([:m, :order_lines, :sticker], "#{ol}_#{or_history[i+1]}").data[:v] rescue 0
          save_sticker_line(ol, s2-s1, day)
        end
      end
      or_history.each do |tid|
        day = timeline_unf tid
        stickers_total = CabiePio.get([:orders, :stickers_amount], order_id).data.to_i
        sticker_sum = calc_sticker_sum(ar_order.order_lines)
        operc = to_perc(stickers_total, sticker_sum)
        opercd = to_perc(stickers_total, calc_sticker_sum_for_day(ar_order.order_lines, day))
        if operc > 0
          save_sticker_history(order_id, opercd, day)
          save_sticker_progress(order_id, operc)
        end
      end
    end
  end
end