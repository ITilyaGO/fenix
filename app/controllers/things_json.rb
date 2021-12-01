Fenix::App.controllers :things do
  post :list, :provides => :json do
    # @archs = KSM::Archetype.all
    cat = params[:cat]
    products = KSM::Thing.all.select{|a| a.category_id == cat}
    # products = pro.map(&:serializable_hash)
    products.map(&:to_r).each do |p|
      # pm = pro.detect{|a|a.id == p['id']}
      # p[:displayname] = pm&.displayname
    end
    # @archs.select{|a|a.category_id == cat}.map(&:to_r)
    products.to_json
  end
end