Fenix::App.controllers :products do
  get :index do
    redirect url(:products, :index2)
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @products = Product.all.includes(:category).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    @pages = (Product.count/pagesize).ceil
    @r = url(:products, :index)
    render 'products/index'
  end

  get :index2 do
    @title = t 'tit.products.list'
    @product = Product.new(id: -1)
    @xproduct = {}
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    
    render 'products/listform'
  end

  get :e, :with => :id do
    @title = t 'tit.products.list'
    @product = Product.find(params[:id])
    @xproduct = {
      n1c: CabiePio.get([:product, :k1c], @product.id).data,
      arn: CabiePio.get([:product, :archetype], @product.id).data
    }
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    @squadconf = @product.serializable_hash

    render 'products/listform'
  end

  put :updatex, :with => :id do
  end
    
  get :new do
    @title = "New product"
    @product = Product.new
    @cats = Category.where(:category_id => nil)
    render 'products/new'
  end
  
  post :create do
    @product = Product.new(params[:product])
    @cats = Category.where(:category_id => nil)
    if @product.save
      @title = pat(:create_title, :model => "product #{@product.id}")
      flash[:success] = pat(:create_success, :model => 'Product')
      params[:save_and_continue] ? redirect(url(:products, :index)) : redirect(url(:products, :edit, :id => @product.id))
    else
      @title = pat(:create_title, :model => 'product')
      flash.now[:error] = pat(:create_error, :model => 'product')
      render 'products/new'
    end
  end
  
  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "product #{params[:id]}")
    @product = Product.find(params[:id])
    @cats = Category.where(:category_id => nil)
    if @product
      render 'products/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'product', :id => "#{params[:id]}")
      halt 404
    end
  end
  
  put :update, :with => :id do
    @title = pat(:update_title, :model => "product #{params[:id]}")
    @product = Product.find(params[:id])
    if @product
      if @product.update_attributes(params[:product])
        flash[:success] = pat(:update_success, :model => 'Product', :id =>  "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:products, :index)) :
          redirect(url(:products, :edit, :id => @product.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'product')
        render 'products/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'product', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Products"
    product = Product.find(params[:id])
    if product
      if product.destroy
        flash[:success] = pat(:delete_success, :model => 'Product', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'product')
      end
      redirect url(:products, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'product', :id => "#{params[:id]}")
      halt 404
    end
  end
  
  delete :destroy_many do
    @title = "Products"
    unless params[:product_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'product')
      redirect(url(:products, :index))
    end
    ids = params[:product_ids].split(',').map(&:strip)
    products = Product.find(ids)
    
    if Product.destroy products
      flash[:success] = pat(:destroy_many_success, :model => 'Products', :ids => "#{ids.to_sentence}")
    end
    redirect url(:products, :index)
  end
  
  get :tree, :provides => :json do
    json_products_tree
  end
  
  get :tree2, :provides => :json do
    json_cats2.to_json
  end
  
  get :complexity do
    @title = "Product - Complex"
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    @kc_products = CabiePio.folder(:complexity, :product).flat
    @kc_categories = CabiePio.folder(:complexity, :category).flat
    render 'products/complexity'
  end

  put :complexity do
    data = params['cplx']
    products = params['ps'] || []
    CabiePio.clear(:complexity, :product)
    products.each do |p|
      formula = data.select{|l|l['id'] == "p#{p}"}.map{|v|"#{v['level']}:#{v['amount']}"}.join(' ')
      CabiePio.set [:complexity, :product], p, formula
    end
    cats = params['cs'] || []
    CabiePio.clear(:complexity, :category)
    cats.each do |c|
      formula = data.select{|l|l['id'] == "c#{c}"}.map{|v|"#{v['level']}:#{v['amount']}"}.join(' ')
      CabiePio.set [:complexity, :category], c, formula
    end
    $background.in '0s' do
      OrderJobs.complexity_job
    end

    redirect url(:products, :complexity)
  end

  get :sticker do
    @title = "Product - Sticker price"
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    @parents = Product.pluck(:parent_id).compact.uniq
    @kc_products = CabiePio.folder(:products, :sticker).flat
    ps = @kc_products.keys
    @catind = @categories.map{|c|[c.id, (c.all_products.map(&:id) & ps).size]}.to_h
    # @kc_categories = CabiePio.folder(:complexity, :category).flat
    render 'products/sticker'
  end

  put :sticker do
    kc_products = CabiePio.folder(:products, :sticker).flat.trans(nil, :to_f)
    prs = []
    params[:line].each do |k, line|
      prid = line['id'].to_i
      stick = line['sticker'].to_f
      anystick = line['sticker'].size > 0
      CabiePio.unset([:products, :sticker], prid) if anystick && stick == 0
      prs << prid if anystick && stick == 0
      next if kc_products.fetch(prid, 0) == stick
      next unless stick > 0
      CabiePio.set [:products, :sticker], prid, stick
      prs << prid
    end
    # $background.in '0s' do
    OrderJobs.sticker_job_easy(prs)
    # end

    redirect url(:products, :sticker)
  end

  get :export, :provides => :csv do
    parents = Product.pluck(:parent_id).compact.uniq
    fname = 'products-' + Time.new.strftime("%d-%m-%Y") + '.csv'
    headers['Content-Disposition'] = "attachment; filename=#{fname}"
    headers['Content-Type'] = "application/vnd.ms-excel"
    output = ''
    output = "\xEF\xBB\xBF" if params.include? :win
    output << CSV.generate(:col_sep => ';') do |csv|
      # csv << %w(id name num)
      cats = Category.where(category: nil).order(:index => :asc)
      cats.each do |category|
        category.subs_ordered.each do |sub|
          sub.all_products.order(:index => :asc).each do |product|
            next unless product.active
            next if parents.include?(product.id)
            csv << [product.displayname, product.price]
          end
        end
      end
    end
  end


  get :stock do
    # OrderJobs.stock_job(force: true)
    @title = "Product - Stock"
    @day = Date.parse(params[:day]) rescue Date.today
    @holders = {}
    products_hash.keys.each do |sk|
      @holders[sk] ||= {}
    end
    7.times do |i|
      dt = (@day-i).strftime('%y%m%d')
      all_ids = products_hash.keys.map{|p|product_daystock(p, @day-i)}
      stockday = CabiePio.all_keys(all_ids, folder: [:stock, :common, :a]).flat
      stockday.each do |sk, sv|
        p = sk.split('_').first.to_i
        @holders[p] ||= {}
        @holders[p][@day-i] = sv.to_i
      end
    end
    
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    @parents = Product.pluck(:parent_id).compact.uniq
    @kc_products = CabiePio.folder(:stock, :product).flat.trans(nil, :to_i)
    @kc_needs = CabiePio.folder(:need, :product).flat.trans(nil, :to_i)
    catgroup = products_hash.keys.group_by{|k|products_hash[k]}
    @catstock = catgroup.map{|k,v|[k, v.map{|p|@kc_products.fetch(p, 0)}.sum{|x|x<0?x:0}]}.to_h
    @catneed = catgroup.map{|k,v|[k, v.map{|p|@kc_needs.fetch(p, 0)}.sum{|x|x>0?x:0}]}.to_h
    render 'products/stock'
  end

  put :stock do
    params[:lines].each do |k, line|
      line.each do |date, stock_in|

        # stock_in = line['in']
        # stock_out = line['out']
        id = k
        day = Time.parse date
        next if stock_in.size == 0
        # stock_in = date.last
        # id = k

        prev_day = CabiePio.get([:stock, :common, :a], product_daystock(id, day)).data.to_i
        CabiePio.set [:stock, :common, :a], product_daystock(id, day), stock_in.to_i if stock_in.size > 0
        # CabiePio.set [:stock, :common, :n], product_daystock(id), stock_out.to_i if stock_out.size > 0

        # diff = stock_in.to_i - stock_out.to_i
        # if diff != 0
        sum = CabiePio.get [:stock, :product], id
        CabiePio.set [:stock, :product], id, sum.data.to_i + stock_in.to_i - prev_day
      end
    end

    redirect url(:products, :stock)
  end
end
