module Fenix::App::ThingsHelper
  def thing_to_top id
    bo = wonderbox(:things_by_date)
    bo.shift if bo.size == 100
    bo.delete id
    bo << id
    wonderbox_set(:things_by_date, bo.take(100))
  end

  def thing_seed_from cat
    bo = wonderbox(:things_seed) || {}
    seed = bo.fetch(cat, 0) + 1
    bo[cat] = seed
    wonderbox_set(:things_seed, bo)
    seed
  end

  def thing_glob_seed
    bo = wonderbox(:things_glob_seed) || {}
    seed = bo.fetch(:seed, 0) + 1
    bo[:seed] = seed
    wonderbox_set(:things_glob_seed, bo)
    seed
  end

  def cate_seed_from topcat = :root
    topcat ||= :root
    bo = wonderbox(:cat_seed) || {}
    seed = bo.fetch(topcat, 0) + 1
    bo[topcat] = seed
    wonderbox_set(:cat_seed, bo)
    seed
  end

  def sect_seed_root
    seed = wonderbox(:sections, :seed) || 0
    seed += 1
    wonderbox_set(:sections, { seed: seed })
    seed
  end

  def update_autodic thing
    ap = KSM::Dic.find(:autoproduct)
    ap.push(thing.name, and_save: true) if thing.name =~ /w+/
    al = KSM::Dic.find(:autolook)
    al.push(thing.look, and_save: true) if thing.look =~ /w+/
  end

  def otree_rendered place
    KSM::Render.find(:otree, place).contents || otree_render(place)
  end

  def otree_render place
    ren = KSM::Render.find(:otree, place)
    ren = KSM::Render.nest(:otree, place) unless ren.exist?
    ren.contents = otree_cats3 pro_olist(place)
    ren.save
    ren.contents
  end

  def otree_compare thing1, thing2
    aif = thing1.area_should_move thing2
    tif = thing1.tree_should_move thing2
    [(thing1.place_id if aif || tif), (thing2.place_id if aif)]
  end

  def otree_job places
    $background.in '0s' do
      places.each do |place|
        otree_render place
      end
    end
  end

  def otree_cats(arr, root = '0000')
    groups = arr.group_by{ |x| x[:parent] }
    groups.default = []
    groups[root] = arr.select{ |x| x[:parent].nil? }
    i = 0
    build_tree = lambda do |parent|
      i += 1
      return '<div class="alert">BRKN ;(</div>' if i > 1024
    
      partial 'thingcats/tree', locals: {
        parent: parent[:id]||root, groups: groups, build_tree: build_tree,
        name: parent[:name]
      }
    end

    build_tree[:parent => root]
  end

  def otree_cats2(arr, root = '0000')
    groups = arr.group_by(&:parent)
    groups.default = []
    groups[root] = arr.select{ |x| x.parent.nil? }
    ing = []
    build_tree = lambda do |parent|
      raise StandardError.new if ing.include? parent.id
      ing << parent.id

      partial parent.class == SL::Thing ? 'thingcats/ptree' : 'thingcats/tree', locals: {
        parent: parent.id||root, groups: groups, build_tree: build_tree,
        name: parent.name, p: parent
      }
    end

    build_tree[SL::Section.new(:parent => root)] rescue 'Hola!'
  end

  def otree_cats3(arr, root = '0000')
    groups = arr.group_by(&:parent)
    groups.default = []
    groups[root] = arr.select{ |x| x.parent.nil? }
    ing = []
    
    se = Slim::Template.new do
      %{
        wnode.wlevel wid=parent full=(:true if groups[parent].any?) titles=name
      }
    end
    sep = Slim::Template.new do
      %{
        pnode.wlevel wid=parent full=(:true if groups[parent].any?) titles=p.displayname
      }
    end
    build_tree = lambda do |parent|
      raise StandardError.new if ing.include? parent.id
      ing << parent.id

      n = parent.class == SL::Thing ? 'pnode' : 'wnode'
      ser = parent.class == SL::Thing ? sep : se
      out = ser.render('1', parent: parent.id||root, groups: groups, name: parent.name, p: parent)
      out.insert -9, groups[parent.id].sort_by(&:wfindex).map(&build_tree).join
    end

    build_tree[SL::Section.new(:parent => root)]
  end

  def cats_olist
    SL::Section.all + SL::Category.all
    # + [SL::Category.new(id: '3648', category_id: '1762')]
  end

  def pro_olist place
    cats_olist + SL::Thing.which(place)
  end

  def cats_plainlist
    output = []
    s = KSM::Section.all.map(&:to_r).each do |r|
      r[:parent] = nil
    end
    c = KSM::Category.toplevel.map(&:to_jr).each do |r|
      r[:parent] = r[:section_id]
    end
    bc = KSM::Category.all.reject(&:top?).map(&:to_jr).each do |r|
      r[:parent] = r[:category_id]
    end

    output << s
    output << c
    output << bc

    output.flatten
  end

end