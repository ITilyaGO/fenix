module Fenix::App::ArchetypeHelper
  def create_absent_archetypes
    products = Product.all
    with_archs = CabiePio.folder(:product, :archetype).flat.keys
    products.each do |p|
      next if with_archs.include? p.id
      pcat = category_matrix[products_hash[p.id]]
      # next unless [18,21].include? pcat
      next unless [80,75,59,28,85].include? p.category_id.to_i
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

  def arbal_unstock_order(order, di_lines, sum_lines, day)
    # stickers = CabiePio.all_keys(order.order_lines.map(&:product_id), folder: [:products, :sticker]).flat.trans(:to_i, :to_f)
    # line_stickers = CabiePio.all_keys(order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum])
    #   .flat.map{|k,v|[k.to_i,v[:v]]}.to_h
    arches = Stock::Linkage.all.flatless
    multi = Stock::Multi.all.flatless
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      m = multi.fetch(line.product_id, 1)
      real_done = (di_lines[line.id.to_i] || 0)*m
      if real_done != 0
        Stock::Free.find(parch).diff -real_done
        daysum = Stock::Out.find parch, day
        daysum.diff real_done
        daysum.remove if daysum.body.zero?

        prev_ex = KSM::OrderNeed.find parch, line.id, order.id
        if prev_ex.exist?
          whole_done = (sum_lines[line.id.to_i] || 0)*m
          now = whole_done >= line.amount*m ? 0 : line.amount*m - whole_done
          prev_ex.save now
          prev_ex.remove if prev_ex.body.zero?
  
          Stock::Need.find(parch).diff now-prev_ex.body
        end
      end
    end
  end

  def arbal_need_order_edit(order)
    sum_lines = CabiePio.all_keys(order.order_lines.map(&:id), folder: [:m, :order_lines, :sticker_sum])
      .flat.transform_values{|v|v[:v]}
    arches = Stock::Linkage.all.flatless
    multi = Stock::Multi.all.flatless
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      m = multi.fetch(line.product_id, 1)
      prev_ex = KSM::OrderNeed.find parch, line.id, order.id
      whole_done = (sum_lines[line.id] || 0)*m
      now = whole_done >= line.amount*m ? 0 : line.amount*m - whole_done
      if now != prev_ex.body
        prev_ex.save now
        prev_ex.remove if prev_ex.body.zero?
        
        Stock::Need.find(parch).diff now-prev_ex.body
      end
    end
  end

  def arbal_need_order_start(order)
    return if KSM::OrderNeed.query(".*_#{order.id}", type: :regex).any?
    arches = Stock::Linkage.all.flatless
    multi = Stock::Multi.all.flatless
    order.order_lines.each do |line|
      next if line.ignored
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      m = multi.fetch(line.product_id, 1)
      KSM::OrderNeed.find(parch, line.id, order.id).save line.amount*m
      Stock::Need.find(parch).diff (line.amount*m||0)
    end
  end

  def arbal_need_order_mid1(order)
    arches = Stock::Linkage.all.flatless
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      # next if line.done_nil? amount
      prev = KSM::OrderNeed.find parch, line.id, order.id
      # real_done = line.ignored ? 0 : line.done_amount.to_i
      processing = false
      if line.ignored
        prev.remove
        processing = true
      # elsif real_done > 0
      #   CabiePio.set [:need, :order], item, real_done
      #   processing = true
      end
      next unless processing
      # CabiePio.set [:need, :order], product_order(line.product_id, order.id), real_done

      Stock::Need.find(parch).diff -prev.body
    end
  end

  def arbal_need_order_st_fin(order)
    arches = Stock::Linkage.all.flatless
    stickers = CabiePio.all_keys(order.order_lines.map(&:product_id), folder: [:products, :sticker]).flat.keys
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      next unless stickers.include? line.product_id
      
      prev = KSM::OrderNeed.find parch, line.id, order.id
      prev.remove
      Stock::Need.find(parch).diff -prev.body
    end
  end

  def arbal_need_order_fin(order)
    arches = Stock::Linkage.all.flatless
    stickers = CabiePio.all_keys(order.order_lines.map(&:product_id), folder: [:products, :sticker]).flat.keys
    multi = Stock::Multi.all.flatless
    doneday = CabiePio.get([:stock, :order, :done], order.id).data
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch

      unless stickers.include? line.product_id
        m = multi.fetch(line.product_id, 1)
        real_done = (line.ignored ? 0 : line.done_amount||line.amount)*m
        if real_done > 0
          Stock::Free.find(parch).diff -real_done

          daysum = Stock::Out.find parch, Date.parse(doneday)
          daysum.diff real_done
          daysum.remove if daysum.body.zero?
        end
      end

      prev = KSM::OrderNeed.find parch, line.id, order.id
      prev.remove
      Stock::Need.find(parch).diff -prev.body
    end
    arbal_need_order_rep(order)
  end

  def arbal_need_order_done(order)
    done = CabiePio.get([:stock, :order, :done], order.id)
    CabiePio.set [:stock, :order, :done], order.id, Time.now if done.blank?
  end

  def arbal_need_order_fin1(order)
    arches = Stock::Linkage.all.flatless
    order.order_lines.each do |line|
      parch = arches.fetch(line.product_id, nil)
      next unless parch
      prev = KSM::OrderNeed.find parch, line.id, order.id
      real_done = line.ignored ? 0 : line.done_amount||line.amount
      prev.remove

      Stock::Need.find(parch).diff -prev.body
      Stock::Free.find(parch).diff -real_done
    end
    arbal_need_order_rep(order)

    CabiePio.set [:stock, :order, :done], order.id, Time.now
  end

  def arbal_need_order_rep(order)
    KSM::OrderNeed.query(".*_#{order.id}", type: :regex).flatless.each do |k, v|
      p = k.split('_')

      Stock::Need.find(p.first).diff -v
      KSM::OrderNeed.find(*p).remove
    end

    # bal_need_order_start(order)
  end
end