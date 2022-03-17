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
    @products = Product.find_all(ids).sort_by{|a| ids.index(a.id)}
    if ccat = params[:cat]
      @products = Product.all.select{ |a| a.category_id == ccat }
      @product = Product.new({ category_id: ccat })
      @ccat = ccat
    end
    if townfilter = params[:place]
      @products = @products.select{ |a| a.place_id == townfilter }
      @place = townfilter
    end
    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)
    # Product.all.includes(:category).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    @pages = 1

    @cats = KSM::Category.toplevel

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
    @product = Product.find(params[:id])
    @kc_place = KatoAPI.anything(@product.place_id)
    @xproduct = SL::Product.new @product.id
    @cats = KSM::Category.toplevel
    # @categories = Category.all.includes(:category)

    ids = wonderbox(:things_by_date).reverse
    @products = Product.find_all(ids).sort_by{|a| ids.index(a.id)}
    if ccat = params[:cat]
      @products = Product.all.select{ |a| a.category_id == ccat }
      @product.category_id = ccat unless @product.exist?
      @ccat = ccat
    end
    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)
    @squadconf = @product.serializable_hash

    render 'things/listform'
  end

  put :update, :with => :id do
    @product = Product.find(params[:id])
    @product = Product.nest if params[:id] == '0000' || params[:clone]
    form = params[:product]
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

  get :transfer do
    render 'things/transfer'
  end

  post :transfer do
    file = params[:file]
    tempfile = file[:tempfile]
    lines = CSV.read(tempfile.path, :headers => :first_row, col_sep: ';', header_converters: lambda { |a| a.to_sym }) rescue []
    @counter = 0
    @products = []
    lines.each do |line|
      product = Product.find(line[:id]) unless line[:id]&.blank?
      # product = Product.nest unless product&.exist?
      item = {
        name: line[:name],
        category_id: line[:category].split(':').first,
        place_id: line[:place].split(':').first,
        price: line[:price],
        sn: line[:sku].split('.').last,
        desc: line[:desc],
        weight: line[:weight],
        height: line[:height]
        # bbid: line[:bb],
        # barcode: line[:barcode]

      }

      product.formiz item
      # product.sn ||= thing_glob_seed
      # product.saved_by @current_account
      @products << product
      @counter += 1
    end
    tempfile.unlink

    render 'things/transfer'
  end

  get :export, :with => :id, :provides => :csv do
    is_sample = params[:id] == 'sample'
    ids = wonderbox(:things_by_date).reverse
    @products = Product.find_all(ids).sort_by{|a| ids.index(a.id)}
    if !is_sample && ccat = params[:id]
      @products = Product.all.select{ |a| a.category_id == ccat }
    end
    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)
    cats = KSM::Category.all.map{ |c| [c.id, c.hiername] }.to_h

    fname = 'pio-excel.csv'
    headers['Content-Disposition'] = "attachment; filename=#{fname}"
    output = ''
    output = "\xEF\xBB\xBF" if params.include? :win
    output << CSV.generate(:col_sep => ';') do |csv|
      csv << %w(id name brand category place price sku bb k1c barcode img weight height desc)
      @products.each do |t|
        xt = SL::Product.new t.id
        csv << [t.id, t.name, t.category.section.name, cats[t.category_id],
          t.hierplace(@kc_towns[t.place_id]&.model), t.price, t.autoart, xt.arn, xt.k1c, t.autobar,
          t.sketch_ext, t.weight, t.height, t.desc
        ]
      end
    end
  end
end