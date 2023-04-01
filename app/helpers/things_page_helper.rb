module Fenix::App::ThingsPageHelper
  def none_to_nil(val)
    val == 'none' ? nil : val
  end

  def filter_products_with_category(cat)
    cat = nil if cat.to_sym.eql? :nothing
    @products = @products.select{ |a| a.category_id == cat }
    @product = Product.new({ category_id: cat })
  end

  def filter_products_with_search(search)
    if search
      search_list = (search || '').downcase.split(/[\s,.'"()-]/).compact
      @products.select! do |p|
        pdn_d = p.displayname.downcase
        search_list.all?{ |w| pdn_d.include?(w) }
      end
    end
  end

  def last_products_by_filters(townfilter, ccat)
    ids = wonderbox(:things_by_date).reverse
    @products = Product.find_all(ids).sort_by{ |a| ids.index(a.id) }
    @products = @products.select{ |a| a.place_id == townfilter } if townfilter
    filter_products_with_category(ccat) if ccat
  end

  def products_by_filters(params)
    ccat = none_to_nil params[:cat]
    townfilter = none_to_nil params[:place]
    search = params[:search]
    if (ccat.nil? || townfilter.nil?) && params[:search].nil?
      @notice = 'Выберите город и категорию' if ccat || townfilter
      last_products_by_filters(townfilter, ccat)
    else
      ccat = nil if ccat == 'all' && townfilter != 'all'
      townfilter = nil if townfilter == 'all' && ccat != 'all'
      @products = townfilter ? Product.which(townfilter) : Product.all
      filter_products_with_category(ccat) if ccat
      filter_products_with_search(search) if search
      @products.sort_by!(&:cindex)
    end
  end
end
