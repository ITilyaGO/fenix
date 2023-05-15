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
    products.each do |pa|
      pm = pro.detect{|a|a.id == pa[:id]}
      pa[:name] = pm&.displayname
      pa[:arn] = @kc_stocks[@arp[pa[:id]]]
      pa[:pic] = picsrc(pm&.id) 
    end
    products.to_json
  end

  post :one, :provides => :json do
    id = params[:id]
    pic = { pic: picsrc(id) }
    Product.find(id).to_jr.merge(pic).to_json
  end

  post :list_by_filters, :provides => :json do
    products = products_by_filters(params)
    data = products&.map do |p|
      xt = SL::Product.new p.id
      { id: p.id,
        name: p.name,
        look: p.look,
        category_id: p.category_id,
        place_id: p.place_id,
        price: p.price,
        desc: p.desc,
        corel: p.corel,
        art: p.art,
        discount: p.discount,
        dim_weight: p.dim_weight,
        dim_height: p.dim_height,
        dim_width: p.dim_width,
        dim_length: p.dim_length,
        windex: p.windex,
        lotof: p.lotof,
        lotof_mfg: p.lotof_mfg,
        tagname: p.tagname,
        # bbid: p.bbid,
        displayname: p.displayname,
        arn: xt.arn,
        sticker: xt.sticker,
        multi: xt.multi,
        pit: p.settings&.fetch(:pi, 0)
      }
    end
    data.to_json
  end
end