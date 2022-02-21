module Fenix::App::MigrateHelpers
  def products_to_things_013_up force: nil
    sections = to_thingsecs_up
    cats = to_thingcats_up sections
    products = Product.all
    KSM::Thing.destroy_all if force
    backorder = []
    plookup = {}
    products.each do |p|
      thing = KSM::Thing.nest
      thing.name = p.name
      # thing.category_id = p.category_id
      thing.category_id = cats[p.category_id.to_i]
      thing.place_id = 'RU-YAR-ARO'
      thing.art = p.des
      thing.price = p.price
      thing.saved_by @current_account

      backorder << thing.id
      plookup[p.id] = thing.id
    end
    wonderbox_set(:things_by_date, backorder.pop(50))
    ol_move_up plookup
    arch_move_up plookup
    # os_move_up sections

    CabiePio.wire.sync(true)
  end

  def arch_move_up plookup
    arp = CabiePio.folder(:product, :archetype).flat.trans(:to_i)
    # File.write 'tmp/arch.yaml', YAML.dump(arp)
    # return
    CabiePio.clear(:product, :archetype)
    arp.each do |k,v|
      CabiePio.set [:product, :archetype], plookup[k], v
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
end