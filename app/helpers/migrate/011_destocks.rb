module Fenix::App::MigrateHelpers
  def order_destocks_011_up(force: false)
    CabiePio.clear(:stock, :common, :d) if force

    start_from = Date.today.next_month(-2)

    orders = Order.all
      .includes(:order_parts)
      .where("status >= ?", Order.statuses[:finished])
      .where('updated_at > ?', start_from)
      .order(:updated_at => :desc)

    orders.each do |order|
      mig_order_fin_destock(order)
    end

    mnths = timeline_months start_from
    focused = CabieAssist.focus([:i, :orders, :sticker_date], mnths)
    last_stickers = CabiePio.all_keys(focused, folder: [:i, :orders, :sticker_date]).flat.keys
      .map{|k|k.split(Fenix::App::IDSEP).last.to_i}
    
    Order.where(id: last_stickers).each do |order|
      mig_bal_unstock_order(order)
    end
  end

  def mig_bal_unstock_order(order)
    arches = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    multi = CabiePio.folder(:product, :archetype_multi).flat.trans(:to_i, :to_i)
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      m = multi.fetch(line.product_id, 1)

      sall = CabiePio.all([:m, :order_lines, :sticker], ["#{line.id}_"]).flat

      sall.each do |k, sday|
        day = timeline_unf sday[:t]
        real_done = sday[:v]*m
        
        daysum = CabiePio.get([:stock, :common, :d], archetype_daystock(parch, day)).data.to_i || 0
        CabiePio.set [:stock, :common, :d], archetype_daystock(parch, day), daysum+real_done
        CabiePio.unset [:stock, :common, :d], archetype_daystock(parch, day) if daysum+real_done == 0
      end
    end
  end

  def mig_order_fin_destock(order)
    arches = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    stickers = CabiePio.all_keys(order.order_lines.map(&:product_id), folder: [:products, :sticker]).flat.trans(:to_i).keys
    multi = CabiePio.folder(:product, :archetype_multi).flat.trans(:to_i, :to_i)
    doneday = CabiePio.get([:stock, :order, :done], order.id).data
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch

      unless stickers.include? line.product_id
        m = multi.fetch(line.product_id, 1)
        real_done = (line.ignored ? 0 : line.done_amount||line.amount)*m
        if real_done > 0
          daysum = CabiePio.get([:stock, :common, :d], archetype_daystock(parch, Date.parse(doneday))).data.to_i || 0
          CabiePio.set [:stock, :common, :d], archetype_daystock(parch, Date.parse(doneday)), daysum+real_done
          CabiePio.unset [:stock, :common, :d], archetype_daystock(parch, Date.parse(doneday)) if daysum+real_done == 0
        end
      end
    end
  end
end