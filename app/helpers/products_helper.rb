module Fenix::App::ProductsHelper
  def pluralize(count, singular, fifth = nil, plural)
    word = if (count == 1 || count =~ /^1(\.0+)?$/)
      singular
    elsif count < 5
      fifth || plural
    else
      plural || singular.pluralize
    end
    word
  end
  
  def product_image(id, image = 1)
    "/images/#{id.to_s.rjust(3, '0')}-#{image}.png"
  end

  def categories_tag(name, options={})
    options = { :name => name }.merge(options)
    options[:name] = "#{options[:name]}[]" if options[:multiple]
    content_tag(:select, extract_option_tags!(options), options)
  end
  
  # def extract_option_tags!(options)
  #   state = extract_option_state!(options)
  #   option_tags = grouped_options_for_select(options.delete(:grouped_options), state)

  #   if prompt = options.delete(:include_blank)
  #     option_tags.unshift(blank_option(prompt))
  #   end
  #   option_tags
  # end
  
  def cache_product_section
    Padrino.cache[:products_section] ||= store_product_section
  end

  def store_product_section
    ps = Product.all
    ps.map{|p|[p.id, p.category.category.section_id]}.to_h
  end

  def product_to_section(product)
    cache_product_section.fetch(product, nil)
  end

  def json_clients()
    nodes = Client.includes(:place).all
    nodes.map do |node|
      # name = [node.name, node.org].reject(&:blank?).join(", ")
      { :name => node.name, :id => node.id, :city => node.place_name }
    end
  end

  def json_products_list
    Padrino.cache[:products_list] ||= json_list.to_json
  end

  def json_products_tree
    Padrino.cache[:products_tree] ||= json_cats.to_json
  end
  
  def reset_products_list
    Padrino.cache.delete(:products_list)
    Padrino.cache.delete(:products_tree)
    Padrino.cache.delete(:products_section)
  end

  def json_list
    Product.all.map{|a| {id: a.id, price: a.price, name: a.displayname}}

    # parents = Product.pluck(:parent_id).compact.uniq
    # Product.joins(:category).eager_load(:parent).select(:id, :name, :price)
    #   .reject{|a| parents.include? a[:id]}
    #   .map{|a| {id: a[:id], price: a[:price], name: a.displayname}}
  end

  def json_cats
    @parents = Product.pluck(:parent_id).compact.uniq
    nodes = Category.where(:category => nil)
    nodes.map do |node|
      { :title => node.name, :key => node.id, :children => json_subs(node).compact }
    end
  end
  
  def json_subs(node)
    nodes = node.subcategories.order(:index => :asc)
    nodes.map do |node|
      next if !node.all_products.any?
      { :title => node.name, :key => node.id, :lazy => true, :children => json_prods(node).compact }
    end
  end
  
  def json_prods(node)
    nodes = node.all_products.includes(:parent).order(:index => :asc)
    nodes.map do |node|
      next if @parents.include? node.id
      { :title => node.displayname, :key => node.id }
    end
  end

  def json_cats2()
    nodes = Category.where(:category => nil)
    nodes.map do |node|
      { :text => node.name, :key => node.id, :children => json_subs2(node).compact }
    end
  end
  
  def json_subs2(node)
    nodes = node.subcategories
    nodes.map do |node|
      next if !node.products.any?
      { :text => node.name, :key => node.id, :children => json_prods2(node).compact }
    end
  end
  
  def json_prods2(node)
    nodes = node.products
    nodes.map do |node|
      { :text => node.name, :key => node.id }
    end
  end

  # def calc_complexity_for(order)
  #   cplx = order_complexity order
  #   CabiePio.set [:complexity, :order], order.id, cplx
  #   @complex_hash = nil
  # end

  # def order_cplx(id)
  #   cabie = CabiePio.get [:complexity, :order], id
  #   cabie.data
  # end

  def product_order(product, oline, order)
    "#{product}_#{oline}_#{order}"
  end

  def product_daystock(product, day = Date.today)
    "#{product}_#{timeline_id(day)}"
  end

  # def bal_stock_order_both(order)
  #   order.order_lines.each do |line|
  #     prev = CabiePio.get([:need, :order], product_order(line.product_id, line.id, order.id)).data.to_i || 0
  #     next if line.ignored
  #     CabiePio.set [:need, :order], product_order(line.product_id, line.id, order.id), line.amount
  #     # CabiePio.set [:stock, :order, :a], product_order(line.product_id, order.id), line.done_amount

  #     psum = CabiePio.get([:stock, :product], line.product_id).data.to_i || 0
  #     CabiePio.set [:stock, :product], line.product_id, psum+(line.done_amount||0)-(line.amount||0)
  #   end
  # end

  def bal_need_order_start(order)
    order.order_lines.each do |line|
      next if line.ignored
      CabiePio.set [:need, :order], product_order(line.product_id, line.id, order.id), line.amount
      psum = CabiePio.get([:need, :product], line.product_id).data.to_i || 0
      CabiePio.set [:need, :product], line.product_id, psum+(line.amount||0)
    end
  end

  def bal_need_order_mid(order)
    order.order_lines.each do |line|
      # next if line.done_nil? amount
      item = product_order(line.product_id, line.id, order.id)
      prev = CabiePio.get([:need, :order], item).data.to_i || 0
      real_done = line.ignored ? 0 : line.done_amount.to_i
      processing = false
      if line.ignored
        CabiePio.unset [:need, :order], item
        processing = true
      elsif real_done > 0
        CabiePio.set [:need, :order], item, real_done
        processing = true
      end
      next unless processing
      # CabiePio.set [:need, :order], product_order(line.product_id, order.id), real_done

      psum = CabiePio.get([:need, :product], line.product_id).data.to_i || 0
      CabiePio.set [:need, :product], line.product_id, psum-prev+real_done
    end
  end

  def bal_need_order_fin(order)
    order.order_lines.each do |line|
      prev = CabiePio.get([:need, :order], product_order(line.product_id, line.id, order.id)).data.to_i || 0
      real_done = line.ignored ? 0 : line.done_amount||line.amount
      CabiePio.unset [:need, :order], product_order(line.product_id, line.id, order.id)
      # CabiePio.set [:need, :order], product_order(line.product_id, order.id), real_done

      psum = CabiePio.get([:need, :product], line.product_id).data.to_i || 0
      CabiePio.set [:need, :product], line.product_id, psum-prev

      ssum = CabiePio.get([:stock, :product], line.product_id).data.to_i || 0
      CabiePio.set [:stock, :product], line.product_id, ssum-real_done
    end
    bal_need_order_rep(order)

    CabiePio.set [:stock, :order, :done], order.id, Time.now
  end

  def bal_need_order_rep(order)
    old_need = CabiePio.query("p/need/order>.*_#{order.id}", type: :regex).flat
    old_need.each do |k, v|
      p = k.split('_').first

      psum = CabiePio.get([:need, :product], p).data.to_i || 0
      CabiePio.set [:need, :product], p, psum-v.to_i

      CabiePio.unset [:need, :order], k
    end

    # bal_need_order_start(order)
  end

  def products_hash
    @products_hash ||= Product.all.map{ |p| [p.id, p.category_id] }.to_h
  end

  def category_matrix
    @category_matrix ||= KSM::Category.all.map{ |c| [c.id, c.category_id] }.to_h
  end

  def section_matrix
    @section_matrix ||= Category.where(category_id: nil).pluck(:id, :section_id).to_h
  end

  def category_grouped
    @cat_group ||= Category.all.group_by(&:category_id)
  end

  def category_parent(product)

  end

  def all_catagories
    @all_catagories ||= Category.all
  end

  def all_products_for sub
    @ksm_pro_gr ||= Product.all.group_by(&:category_id)
    
    @ksm_pro_gr.fetch(sub, [])
  end

  private

  # def options_for_select(option_items, state = {})
  #   return [] if option_items.blank?
  #   option_items.each do |opt|
  #     html_attributes = { :value => opt.id ||= opt.name }.merge(opt.attributes||{})
  #     html_attributes[:selected] ||= option_is_selected?(opt.id, opt.name, state[:selected])
  #     html_attributes[:disabled] ||= option_is_selected?(opt.id, opt.name, state[:disabled])
  #     content_tag(:option, opt.name, html_attributes)
  #   end
  # end
  
  # def grouped_options_for_select(collection, state = {})
  #   collection.map do |item|
  #     caption = item.name
  #     # attributes = item.last.kind_of?(Hash) ? item.pop : {}
  #     value = item.subcategories
  #     attributes = value.pop if value.last.kind_of?(Hash)
  #     html_attributes = { :label => caption }.merge(attributes||{})
  #     content_tag(:optgroup, options_for_select(value, state), html_attributes)
  #   end
  # end

end
