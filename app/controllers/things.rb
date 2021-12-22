Fenix::App.controllers :things do
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

  get :table do
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    ids = wonderbox(:things_by_date).reverse
    @products = KSM::Thing.find_all(ids).sort_by{|a| ids.index(a.id)}
    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)
    # Product.all.includes(:category).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    @pages = 1
    @r = url(:products, :index)
    render 'things/table'
  end

  get :index2 do
    @title = t 'tit.products.list'
    @product = Product.new(id: -1)
    @xproduct = {}
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    
    render 'products/listform'
  end

  get :edit, :with => :id do
    @title = t 'tit.products.list'
    @product = KSM::Thing.find(params[:id])
    @kc_place = KatoAPI.anything(@product.place_id)
    @xproduct = {
      n1c: CabiePio.get([:product, :k1c], @product.id).data,
      arn: CabiePio.get([:product, :archetype], @product.id).data
    }
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)
    @squadconf = @product.serializable_hash

    ids = wonderbox(:things_by_date).reverse
    @products = KSM::Thing.find_all(ids).sort_by{|a| ids.index(a.id)}
    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)

    render 'things/listform'
  end

  put :update, :with => :id do
    @product = KSM::Thing.find(params[:id])
    @product = KSM::Thing.nest if params[:id] == '0000' || params[:clone]
    form = params[:ksm_thing]
    @product.formiz(form)
    @product.sn ||= thing_glob_seed
    @product.saved_by @current_account
    thing_to_top @product.id
    if @product
      if true
        flash[:success] = pat(:update_success, :model => 'Product', :id =>  "#{@product.id}")
        params[:save_and_continue] ?
          redirect(url(:things, :index)) :
          redirect(url(:things, :edit, :id => @product.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'product')
        render 'products/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'product', :id => "#{params[:id]}")
      halt 404
    end
  end
end