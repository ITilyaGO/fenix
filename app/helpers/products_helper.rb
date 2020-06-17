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
  end

  def json_list
    parents = Product.pluck(:parent_id).compact.uniq
    Product.joins(:category).eager_load(:parent).select(:id, :name, :price)
      .reject{|a| parents.include? a[:id]}
      .map{|a| {id: a[:id], price: a[:price], name: a.displayname}}
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
      next if !node.products.any?
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

  def products_hash
    @products_hash ||= Product.all.pluck(:id, :category_id).map{|a|[a.first, a.last.to_i]}.to_h
  end

  def category_matrix
    @category_matrix ||= Category.all.pluck(:id, :category_id).to_h
  end

  def category_parent(product)

  end

  def all_catagories
    @all_catagories ||= Category.all
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
