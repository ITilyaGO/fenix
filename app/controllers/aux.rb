Fenix::App.controllers :aux do
  post :old_categories, :provides => :json do
    comp = params[:section].to_i
    # usergroups = KSM::UserGroup.all.map(&:to_r)
    usergroups = Category.all
    bcats = Category.all.select{|a| a.section_id == comp}.map(&:id)
    usergroups = Category.all.select{|a| a.section_id == comp}.map(&:serializable_hash)
    usergroups.each do |a|
      a[:childs] = category_grouped[a['id']].map(&:serializable_hash)
      # a[:name] = '' if a[:name].nil?
    end
    usergroups.to_json
  end

  post :old_sections, :provides => :json do
    comp = params[:brand]
    # usergroups = KSM::UserGroup.all.map(&:to_r)
    usergroups = Section.all.map(&:serializable_hash)
    usergroups.each do |a|
      # a[:name] = '' if a[:name].nil?
    end
    usergroups.to_json
  end

  post :categories, :provides => :json do
    comp = params[:section]
    # usergroups = KSM::UserGroup.all.map(&:to_r)
    usergroups2 = KSM::Category.all
    bcats = KSM::Category.all.select{|a| a.section_id == comp}.map(&:id)
    usergroups = KSM::Category.all.select{|a| a.section_id == comp}.sort_by(&:display).map(&:to_jr)
    grouped = KSM::Category.all.group_by(&:category_id)
    usergroups.to_json
  end

  post :topcategories, :provides => :json do
    comp = params[:section]
    usergroups = KSM::Category.all.select{|a| a.category_id.nil? && a.section_id == comp}.sort_by(&:display).map(&:to_jr)
    usergroups.to_json
  end

  post :sections, :provides => :json do
    comp = params[:brand]
    # usergroups = KSM::UserGroup.all.map(&:to_r)
    usergroups = KSM::Section.all.map(&:to_r)
    usergroups.each do |a|
      # a[:name] = '' if a[:name].nil?
    end
    usergroups.to_json
  end

  post :current_orders, :provides => :json do
    orders = Order.where("status > ?", Order.statuses[:draft]).where("status < ?", Order.statuses[:finished]).pluck(:id)
    @kc_orders = CabiePio.all_keys(orders, folder: [:orders, :towns]).flat
    @kc_towns = KatoAPI.batch @kc_orders.values.uniq
    results = orders.map{|a|{id:a, keyword:a.to_s, city: @kc_towns[@kc_orders[a.to_s]]&.model&.name}}
    results.to_json
  end

  post :deliveries, :provides => :json do
    # usergroups = KSM::UserGroup.all.map(&:to_r)
    usergroups = Order.deliveries.map{|k,v| { id: k, name: tj(:delivery, k)} }
    usergroups.each do |a|
      # a[:name] = '' if a[:name].nil?
    end
    usergroups.to_json
  end

  post :stadies, :provides => :json do
    stadies = wonderbox :stadie_grade
    st = stadies.map{|k| { id: k, name: tj(:stadie, k)} }
    st.to_json
  end

end