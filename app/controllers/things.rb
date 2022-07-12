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
      @products = Product.all.select{ |a| a.category_id == ccat }.sort_by(&:cindex)
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

    @cats = KSM::Category.toplevel.sort_by(&:wfindex)

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
    @cats = KSM::Category.toplevel.sort_by(&:wfindex)
    # @categories = Category.all.includes(:category)

    ids = wonderbox(:things_by_date).reverse
    @products = Product.find_all(ids).sort_by{|a| ids.index(a.id)}
    if ccat = params[:cat]
      @products = Product.all.select{ |a| a.category_id == ccat }.sort_by(&:cindex)
      @product.category_id = ccat unless @product.exist?
      @ccat = ccat
    end
    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)
    @squadconf = @product.serializable_hash
    @product.id = '0000' if params[:clone]

    render 'things/listform'
  end

  put :update, :with => :id do
    tid = params[:id]
    @product = Product.find tid
    @product = Product.nest if tid == '0000' || params[:clone]
    @product.origin = tid if params[:clone]
    form = params[:product]
    @product.clear_formize(form)
    @product.sn ||= thing_glob_seed
    @product.saved_by @current_account
    thing_to_top @product.id
    update_autodic @product
    xproduct = SL::Product.new @product.id
    xproduct.raw = params[:raw]
    xproduct.save_links
    @product.backsync if @product.global?
    known_cities_add @product.place_id
    OrderAssist.reset_products_list
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
      product = Product.find(id = line[:id]) unless id&.blank? || id.eql?('уин')
      next if id.eql?('уин')
      # product = Product.nest unless product&.exist?
      item = {
        name: line[:type],
        look: line[:view],
        category_id: line[:category].split(':').first,
        place_id: line[:place].split(':').first,
        price: line[:price],
        sn: line[:sku].split('.').last,
        desc: line[:desc],
        corel: line[:corel],
        art: line[:art],
        dim_weight: line[:weight],
        dim_height: line[:height],
        dim_width: line[:width],
        dim_length: line[:length]
        
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
    cats = KSM::Category.all.map{ |c| [c.id, c.idname] }.to_h

    fname = 'pio-excel.csv'
    headers['Content-Disposition'] = "attachment; filename=#{fname}"
    output = ''
    output = "\xEF\xBB\xBF" if params.include? :win
    output << CSV.generate(:col_sep => ';') do |csv|
      csv << %w(id name topcat category type place view price art img corel bb
        weight height width length sku barcode desc)
      csv << %w(уин название отдел группа тип город вид цена артикул картинка собрание склад
        вес высота ширина длина индекс штрихкод описание)
      @products.each do |t|
        xt = SL::Product.new t.id
        csv << [t.id, t.displayname, t.category.category.name, cats[t.category_id], t.name,
          t.hierplace(@kc_towns[t.place_id]&.model), t.look, t.price, t.art, t.sketch_ext, t.fullcorel,
          xt.arn, t.dim_weight, t.dim_height, t.dim_width, t.dim_length, t.autoart, t.autobar, t.desc
        ]
      end
    end
  end
end