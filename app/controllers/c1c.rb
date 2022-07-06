Fenix::App.controllers :c1c do
  get :index do
    render ''
  end

  get :settings do
    render 'c1c/settings'
  end

  post :xml_up do
    file = params[:file]
    tempfile = file[:tempfile]
    Xmlp.create_from_file tempfile.path
    tempfile.unlink

    redirect url(:c1c, :pr)
  end

  get :pref do
    n = {
      org: 'b0aa583a-ac9f-11e9-8725-74d435d737ac',
      pricetype: '84e07b11-8aa2-11e0-aea0-001bfc7ad411',
      warehouse: 'f06d81ec-b2a6-11e9-ba86-94de80649ff3',
      responsible: '59a7d749-bd1b-11ea-ba9c-94de80649ff3',
      currency: '58f95f32-aa6c-11e9-8725-74d435d737ac',
      # contract: 'cad7ed1e-4358-11ea-9f0f-fc4dd435bed8',
      bank: '43a488e7-ad33-11e9-8725-74d435d737ac',
    }
    # wonderbox_set(:schema, 8)
    wonderbox_set(:w1c, { number: 8000 }) unless wonderbox(:w1c, :number)
    wonderbox_set(:edict, n)
    @edict = wonderbox(:edict)
    @num = wonderbox(:w1c, :number)
    render 'c1c/display'
  end

  get :create, :with => :id, :provides => :xml do
    headers['Content-Disposition'] = "attachment; filename=pio-to-1c.xml"
    headers['Content-Type'] = "application/xml"
    order = Order.find(params[:id])
    # unless params[:force]
    #   redirect_to url(:c1c, :absent, id: order.id) if check_absent_1c(order).any?
    # end
    output = "\xEF\xBB\xBF"
    # output = []
    output << Xmlfr.customer_order2(order).force_encoding('utf-8')
  end

  get :absent, :with => :id do
    order = Order.find(params[:id])
    @lines = Product.find check_absent_1c(order)

    render 'c1c/absent'
  end

  post :products, :provides => :json do
    links = CabiePio.folder(:product, :k1c).flat
    parents = Product.pluck(:parent_id).compact.uniq
    prs = Product.joins(:category).eager_load(:parent).select(:id, :name, :price)
      .reject{|a| parents.include? a[:id]}
      .map{|a| {id: a.id, c: a.category.name, name: a.displayname, link: links.keys.include?(a.id) }}
    prs.to_json
  end

  get :orders do
    a = KSM1C::Cat.all
    @items = []
    a.each do |item|
      next if item.kind == 'CatalogObject.Номенклатура'
      # next if item.at_path('IsFolder') != 'true'
      p1 = KSM1C::Cat.find(item.parent)

      # next unless ps.include? p3.id 
      # next if item.kind != 'CatalogObject.НоменклатурнаяГруппа'
      @items << item
    end
    render "c1c/opr"
  end

  get :pr do
    root = params[:root]
    a = KSM1C::Cat.all
    @items = []
    ps = ['8fce56f0-8a9d-11e0-aea0-001bfc7ad411', '7c3ea1c7-9058-11ea-af7f-cc52af44fb28',
      'd8c3f498-6684-11e0-99f5-001e5848397d', 'd8c3f492-6684-11e0-99f5-001e5848397d'
    ]
    ps = [root] if root
    a.each do |item|
      next if item.kind != 'CatalogObject.Номенклатура'
      next if item.at_path('IsFolder') != 'true'
      p1 = KSM1C::Cat.find(item.parent)
      p2 = KSM1C::Cat.find(p1.parent)
      p3 = KSM1C::Cat.find(p2.parent)
      next unless ps.include?(p3.id) || ps.include?(p2.id) || ps.include?(p1.id)
      # next if item.kind != 'CatalogObject.НоменклатурнаяГруппа'
      @items << item
    end
    render "c1c/pr"
  end

  get :list_cat, :with => :id do
    a = KSM1C::Cat.all
    @category = KSM1C::Cat.find(params[:id])
    @items = []
    a.each do |item|
      next if item.kind != 'CatalogObject.Номенклатура'
      # next if item.at_path('IsFolder') != 'true'
      next unless item.parent == params[:id]
      @items << item
    end
    @plinks = CabiePio.all_keys(@items.map(&:id), folder: [:k1c, :product]).flat
    render "c1c/products"
  end

  get :desc_product, :with => :id do
    # a = KSM1C::Cat.all
    @product = KSM1C::Cat.find(params[:id])
    pid = CabiePio.get([:k1c, :product], @product.id).data
    @pioprod = Product.find pid if pid
    # @items = []
    # a.each do |item|
    #   next if item.kind != 'CatalogObject.Номенклатура'
    #   # next if item.at_path('IsFolder') != 'true'
    #   next unless item.parent == params[:id]
    #   @items << item
    # end
    render "c1c/product"
  end

  put :link, :with => :id do
    product = Product.find(params[:product])
    k1c = KSM1C::Cat.find(params[:id])
    if k1c.exist? && product
      predp = CabiePio.get([:k1c, :product], k1c.id).data
      pred1 = CabiePio.get([:product, :k1c], product.id).data
      CabiePio.unset([:product, :k1c], predp) if predp
      CabiePio.unset([:k1c, :product], pred1) if pred1
      CabiePio.set [:product, :k1c], product.id, k1c.id
      CabiePio.set [:k1c, :product], k1c.id, product.id
      flash[:success] = pat(:create_success, :model => '1C')
    end
    redirect_to url(:c1c, :pr)
  end

  get :full do
    @cats = KSM::Category.all
    @parents = Product.pluck(:parent_id).compact.uniq
    @c1c_pro = CabiePio.folder(:product, :k1c).flat
    render 'c1c/fulltable'
  end
end