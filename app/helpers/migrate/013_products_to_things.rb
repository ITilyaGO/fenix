module Fenix::App::MigrateHelpers
  def products_to_things_013_up force: nil
    eval "SMProduct = Product; Product = ARProduct;"

    sections = to_thingsecs_up
    cats = to_thingcats_up sections
    products = Product.all
    Product.destroy_all if force
    backorder = []
    plookup = {}
    products.each do |p|
      thing = SMProduct.nest
      thing.name = p.displayname
      # thing.category_id = p.category_id
      thing.category_id = cats[p.category_id.to_i]
      thing.place_id = 'RU'
      thing.art = p.des
      thing.price = p.price
      thing.sn ||= thing_glob_seed
      thing.saved_by @current_account

      backorder << thing.id
      plookup[p.id] = thing.id
    end
    wonderbox_set(:things_by_date, backorder.pop(50))
    
    CabiePio.close
    conf = Cabie.species(:pio).merge({ autosync: false })
    Cabie.room :pio, **conf
    CabiePio.open
    ol_move_up plookup
    m013_arch_move_up plookup, cats
    m013_stickers_move_up plookup
    # os_move_up sections
    m013_accounts_up sections
    m013_orders_move
    m013_k1c_move plookup
    m013_cmplx_move_up plookup, cats

    m013_backmig plookup, cats, sections
    CabiePio.wire.sync(true)

    m013_online plookup, cats
    puts "M013 Complete #{Time.now}"
  end

  def m013_arch_move_up plookup, clookup
    arp = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    # File.write 'tmp/arch.yaml', YAML.dump(arp)
    # return
    CabiePio.clear(:product, :archetype)
    arp.each do |k,v|
      CabiePio.set [:product, :archetype], plookup[k], v
    end

    arpm = CabiePio.folder(:product, :archetype_multi).flat.trans(:to_i)
    CabiePio.clear(:product, :archetype_multi)
    arpm.each do |k,v|
      CabiePio.set [:product, :archetype_multi], plookup[k], v
    end

    KSM::Archetype.all.each do |a|
      a.category_id = clookup[a.category_id]
      a.save
    end
  end

  def m013_stickers_move_up plookup
    stp = CabiePio.folder(:products, :sticker).flat.trans(:to_i)
    CabiePio.clear(:products, :sticker)
    stp.each do |k,v|
      CabiePio.set [:products, :sticker], plookup[k], v
    end
  end

  def m013_cmplx_move_up plookup, clookup
    stp = CabiePio.folder(:complexity, :product).flat.trans(:to_i)
    CabiePio.clear(:complexity, :product)
    stp.each do |k,v|
      CabiePio.set [:complexity, :product], plookup[k], v
    end
    stc = CabiePio.folder(:complexity, :category).flat.trans(:to_i)
    CabiePio.clear(:complexity, :category)
    stc.each do |k,v|
      CabiePio.set [:complexity, :category], clookup[k], v
    end
  end

  def m013_backmig plookup, clookup, slookup
    bmp = KSM::Backmig.find(:product)
    bmp.contents = plookup
    bmp.save
    bmp = KSM::Backmig.find(:category)
    bmp.contents = clookup
    bmp.save
    bmp = KSM::Backmig.find(:section)
    bmp.contents = slookup
    bmp.save
  end

  def m013_online plookup, clookup
    plookup.each do |old, newid|
      op = Online::Product.find old rescue next
      op.pio_id = newid
      op.save
    end
    clookup.each do |old, newid|
      oc = Online::Category.find old rescue next
      oc.pio_id = newid
      oc.save
    end
  end

  def os_move_up lookup
    force = true
    os = KSM::OrderStatus.all
    os.each do |s|
      s.pstate = s.pstate.map{|k,v|[lookup[k],v]}.to_h
      s.save
    end
  end

  def ol_move_up plookup
    force = true
    ols = OrderLine.all #where('created_at > ?', Date.new(2021,1,1))
    # File.write 'tmp/ol.yaml', YAML.dump(ols.each{|a|a.description = nil if a.description&.empty?}.map(&:attributes).map(&:compact))
    # return
    KSM::OrderLine.destroy_all if force
    ols.each do |s|
      thing = KSM::OrderLine.new(id: s.id)
      thing.formiz s.attributes
      thing.product_id = plookup[s.product_id]
      thing.save
    end
  end

  def to_thingsecs_up
    force = true
    sections = Section.all
    KSM::Section.destroy_all if force
    slookup = {}
    sections.each do |s|
      thing = KSM::Section.nest
      slookup[s.id] = thing.id
      thing.formiz s.attributes
      thing.sn ||= sect_seed_root
      thing.ix = s.id
      thing.save
    end
    slookup
  end

  def to_thingcats_up slookup
    force = true
    cats = Category.all
    KSM::Category.destroy_all if force
    lookup = {}
    cats.select{ |c| c.category_id.nil? }.each do |c|
      thing = KSM::Category.nest
      lookup[c.id] = thing.id
      thing.formiz c.attributes
      thing.sn ||= cate_seed_from
      thing.section_id = slookup[c.section_id]
      thing.save
    end
    cats.reject{ |c| c.category_id.nil? }.each do |c|
      thing = KSM::Category.nest
      lookup[c.id] = thing.id
      thing.formiz c.attributes
      thing.category_id = lookup[c.category_id]
      thing.sn ||= cate_seed_from(thing.category_id)
      thing.section_id = KSM::Category.find(thing.category_id).section_id
      thing.save
    end
    lookup
  end

  def m013_accounts_up slookup
    Account.all.each do |a|
      a.section_id = slookup[a.section_id]
      a.save
    end
  end

  def m013_orders_move
    orders = Order.includes(:order_lines_ar).all
    orders.each do |oe|
      begin
        kso = KSM::Order.new oe.attributes
        kso.lines = oe.order_lines_ar_ids
        kso.save
      end rescue nil
    end
  end

  def m013_k1c_move plookup
    stp = CabiePio.folder(:k1c, :product).flat.trans(nil, :to_i)
    CabiePio.clear(:k1c, :product)
    stp.each do |k,v|
      CabiePio.set [:k1c, :product], k, plookup[v]
    end

    stp = CabiePio.folder(:product, :k1c).flat.trans(:to_i)
    CabiePio.clear(:product, :k1c)
    stp.each do |k,v|
      CabiePio.set [:product, :k1c], plookup[k], v
    end
  end
end