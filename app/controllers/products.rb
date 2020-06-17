Fenix::App.controllers :products do
  get :index do
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @products = Product.all.includes(:category).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    @pages = (Product.count/pagesize).ceil
    @r = url(:products, :index)
    render 'products/index'
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
    json_cats.to_json
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

end
