module Fenix::App::ArchetypeHelper
  def create_absent_archetypes
    products = Product.all
    with_archs = CabiePio.folder(:product, :archetype).flat.trans(:to_i).keys
    products.each do |p|
      next if with_archs.include? p.id
      pcat = category_matrix[products_hash[p.id]]
      next unless [18,21].include? pcat
      archetype = KSM::Archetype.nest
      archetype.name = p.name
      archetype.category_id = p.category_id.to_i
      archetype.save

      CabiePio.set [:product, :archetype], p.id, archetype.id
    end
  end

  def archetype_order(archetype, oline, order)
    "#{archetype}_#{oline}_#{order}"
  end

  def archetype_daystock(archetype, day = Date.today)
    "#{archetype}_#{timeline_id(day)}"
  end

  def arbal_unstock_order(order, di_lines, sum_lines)
    # stickers = CabiePio.all_keys(order.order_lines.map(&:product_id), folder: [:products, :sticker]).flat.trans(:to_i, :to_f)
    # line_stickers = CabiePio.all_keys(order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum])
    #   .flat.map{|k,v|[k.to_i,v[:v]]}.to_h
    arches = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    multi = CabiePio.folder(:product, :archetype_multi).flat.trans(:to_i, :to_i)
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      m = multi.fetch(line.product_id, 1)
      real_done = (di_lines[line.id] || 0)*m
      if real_done != 0
        ssum = CabiePio.get([:stock, :archetype], parch).data.to_i || 0
        CabiePio.set [:stock, :archetype], parch, ssum-real_done

        prev = CabiePio.get([:need, :order], archetype_order(parch, line.id, order.id)).data.to_i || 0
        whole_done = (sum_lines[line.id] || 0)*m
        now = whole_done >= line.amount*m ? 0 : line.amount*m - whole_done
        if now == 0
          CabiePio.unset [:need, :order], archetype_order(parch, line.id, order.id)
        else
          CabiePio.set [:need, :order], archetype_order(parch, line.id, order.id), now
        end

        psum = CabiePio.get([:need, :archetype], parch).data.to_i || 0
        CabiePio.set [:need, :archetype], parch, psum-prev+now
      end
    end
  end

  def arbal_need_order_edit(order)
    sum_lines = CabiePio.all_keys(order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum])
      .flat.trans(:to_i).transform_values{|v|v[:v]}
    arches = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    multi = CabiePio.folder(:product, :archetype_multi).flat.trans(:to_i, :to_i)
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      m = multi.fetch(line.product_id, 1)
      prev = CabiePio.get([:need, :order], archetype_order(parch, line.id, order.id)).data.to_i || 0
      whole_done = (sum_lines[line.id] || 0)*m
      now = whole_done >= line.amount*m ? 0 : line.amount*m - whole_done
      if now != prev
        CabiePio.set [:need, :order], archetype_order(parch, line.id, order.id), now

        psum = CabiePio.get([:need, :archetype], parch).data.to_i || 0
        CabiePio.set [:need, :archetype], parch, psum-prev+now
      end
    end
  end

  def arbal_need_order_start(order)
    old_need = CabiePio.query("p/need/order>.*_#{order.id}", type: :regex).flat
    return if old_need.any?
    arches = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    multi = CabiePio.folder(:product, :archetype_multi).flat.trans(:to_i, :to_i)
    order.order_lines.each do |line|
      next if line.ignored
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      m = multi.fetch(line.product_id, 1)
      CabiePio.set [:need, :order], archetype_order(parch, line.id, order.id), line.amount*m
      psum = CabiePio.get([:need, :archetype], parch).data.to_i || 0
      CabiePio.set [:need, :archetype], parch, psum+(line.amount*m||0)
    end
  end

  def arbal_need_order_mid1(order)
    arches = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      # next if line.done_nil? amount
      item = archetype_order(parch, line.id, order.id)
      prev = CabiePio.get([:need, :order], item).data.to_i || 0
      # real_done = line.ignored ? 0 : line.done_amount.to_i
      processing = false
      if line.ignored
        CabiePio.unset [:need, :order], item
        processing = true
      # elsif real_done > 0
      #   CabiePio.set [:need, :order], item, real_done
      #   processing = true
      end
      next unless processing
      # CabiePio.set [:need, :order], product_order(line.product_id, order.id), real_done

      psum = CabiePio.get([:need, :archetype], parch).data.to_i || 0
      CabiePio.set [:need, :archetype], parch, psum-prev
    end
  end

  def arbal_need_order_fin(order)
    arches = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      prev = CabiePio.get([:need, :order], archetype_order(parch, line.id, order.id)).data.to_i || 0
      CabiePio.unset [:need, :order], archetype_order(parch, line.id, order.id)

      psum = CabiePio.get([:need, :archetype], parch).data.to_i || 0
      CabiePio.set [:need, :archetype], parch, psum-prev
    end
    arbal_need_order_rep(order)
  end

  def arbal_need_order_done(order)
    CabiePio.set [:stock, :order, :done], order.id, Time.now
  end

  def arbal_need_order_fin1(order)
    arches = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      prev = CabiePio.get([:need, :order], archetype_order(parch, line.id, order.id)).data.to_i || 0
      real_done = line.ignored ? 0 : line.done_amount||line.amount
      CabiePio.unset [:need, :order], archetype_order(parch, line.id, order.id)
      # CabiePio.set [:need, :order], product_order(line.product_id, order.id), real_done

      psum = CabiePio.get([:need, :archetype], parch).data.to_i || 0
      CabiePio.set [:need, :archetype], parch, psum-prev

      ssum = CabiePio.get([:stock, :archetype], parch).data.to_i || 0
      CabiePio.set [:stock, :archetype], parch, ssum-real_done
    end
    arbal_need_order_rep(order)

    CabiePio.set [:stock, :order, :done], order.id, Time.now
  end

  def arbal_need_order_rep(order)
    old_need = CabiePio.query("p/need/order>.*_#{order.id}", type: :regex).flat
    old_need.each do |k, v|
      p = k.split('_').first

      psum = CabiePio.get([:need, :archetype], p).data.to_i || 0
      CabiePio.set [:need, :archetype], p, psum-v.to_i

      CabiePio.unset [:need, :order], k
    end

    # bal_need_order_start(order)
  end
end