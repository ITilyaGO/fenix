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
    usergroups = KSM::Category.all.select{|a| a.section_id == comp && a.top?}.map(&:to_r)
    grouped = KSM::Category.all.group_by(&:category_id)
    usergroups.each do |a|
      a[:childs] = grouped[a[:id]]&.map(&:to_r)
      a[:name] = usergroups2.detect{|c|c.id == a[:id]}.display
    end
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
    results = orders.map{|a|{id:a, keyword:a.to_s}}
    results.to_json
  end
end