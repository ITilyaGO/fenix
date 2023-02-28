Fenix::App.controllers :products do
  post :list, :provides => :json do
    # @archs = KSM::Archetype.all
    cat = params[:cat].to_i
    pro = Product.where(category_id: cat)
    products = pro.map(&:serializable_hash)
    products.each do |p|
      pm = pro.detect{|a|a.id == p['id']}
      p[:displayname] = pm&.displayname
    end
    # @archs.select{|a|a.category_id == cat}.map(&:to_r)
    products.to_json
  end

  post :clist, :provides => :json do
    cat = params[:cat]
    place = params[:place]
    pro = Product.which(place).select{ |p| p.category_id == cat }.sort_by(&:wfindex)
    @arp = Stock::Linkage.all.flatless
    @kc_stocks = Stock.free.flatless

    products = pro.map(&:to_r).map{|r|r.slice(:id, :name, :art, :price)}
    products.each do |p|
      pm = pro.detect{|a|a.id == p[:id]}
      p[:name] = pm&.displayname
      p[:arn] = @kc_stocks[@arp[p[:id]]]
    end
    products.to_json
  end

  post :one, :provides => :json do
    id = params[:id]
    Product.find(id).to_jr.to_json
  end
end