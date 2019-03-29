Fenix::App.controllers :home, :map => "/" do
  # set :allow_disabled_csrf, true


  get :index do
    # q = params[:q].force_encoding(Encoding::UTF_8)
    # require 'sqlite3'
    # db = SQLite3::Database.new(ActiveRecord::Base.configurations[Padrino.env][:database])
    # like_function = proc do |ctx, x, y|
    #   1 if /#{ x }/ =~ y
    # end
    #   
    # # db.create_function('like', 2, like_function)
    # db.create_function('unlike', 2) do |func, pattern, expression|
    #   # func.result = 1 if /#{ expression }/ =~ pattern
    # 
    #   func.result = (/#{pattern.force_encoding(Encoding::UTF_8)}/i).match(expression.force_encoding(Encoding::UTF_8).to_s) ? 1 : 0
    # end
    # # Place.where('lower(name) unlike ?', q).select(:id, :name).to_json
    # @d1 = db.execute("SELECT * FROM 'places' WHERE UNLIKE('[Яю]рос', name)")
    # # @d1 = (/яРо/i).match("Ярослав")
    # # @d1 = db
    # # redirect url(:home, :catalogr)
    # @rand = SecureRandom.base64(16).gsub(/=+$/,'')
    # @rand = SecureRandom.urlsafe_base64(6)
    render "home/index"
  end

  get :contacts do
    @title = "Контакты"
    render "home/contacts"
  end

  get :intro do
    @p = Order.new
    @p.status = :active
    @p.save
    halt 403
    render "home/intro"
  end

  get :create, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    online = Online::Order.includes(:order_lines).find(params[:id])
    order = online.attributes.merge({:online_id => online.id, :status => :anew})
    Order.create(order)
    if 1
      render 'home/list'
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end


  # get :cart do
  #   halt 404
  #   render "home/cart"
  # end
  # 
  # get :catalog do
  #   redirect url(:home, :catalogr)
  #   # @categories = Category.includes(:subcategories).where(category: nil)
  #   # @products = Product.all
  #   # @active_cat = @categories.first.id
  #   # @cat_title = @categories.first.name
  #   # render "home/catalog"
  # end
  # 
  # get :catalogr, :map => "catalog/recent" do
  #   @categories = Category.where(category: nil).includes(:subcategories).order(:index)
  #   # @all = Product.eager_load(:category).all
  # 
  #   @products = Product.all.order(:created_at => :desc).take(16)
  #   @active_cat = "recent"
  #   @cat_title = "Новинки"
  #   @title = "%s - Каталог" % @cat_title
  #   @ordered = session[:order] || []
  #   render "home/catalog"
  # end
  # 
  # get :catalogall, :map => "catalog/all" do
  #   @categories = Category.where(category: nil).includes(:subcategories).order(:index)
  #   @cats = Category.includes(:products).where.not(category: nil).order(:category_id => :asc)
  # 
  #   # @all = Product.eager_load(:category).all
  # 
  #   # @products = Product.all.select(:id, :name).where(:active => true).to_a
  #   @active_cat = "all"
  #   @cat_title = "Вся продукция"
  #   @title = "%s - Каталог" % @cat_title
  #   # @ordered = !session[:order].nil? ? session[:order].map { |k| k[:id] } : []
  #   @ordered = session[:order] || []
  #   render "home/catalog_all"
  # end
  # 
  # get :catalog, :with => :act_category do
  #   @categories = Category.where(category: nil).includes(:subcategories).order(:index)
  #   # @all = Product.eager_load(:category).all
  #   # ActiveRecord::Associations::Preloader.new(@categories, :subcategories).run()
  # 
  #   @active_cat = params[:act_category].to_i || @categories.first.id
  #   c = Category.find_by_id(@active_cat)
  #   halt 404 if c.nil?
  # 
  #   # @products2 = Product.where(:category => @active_cat, :active => true)
  #   @products = c.products
  #   @cat_title = c.name
  #   @ordered = session[:order] || []
  #   @title = "%s - Каталог" % @cat_title
  #   # all = @all.size
  #   # @cat_title = Category.find(18).subcategories.first.pro_count
  #   # @categories.update(:products)
  #   # @cat_title = Category.find(18).subcategories.first.products.count
  # 
  #   # @active_cat = params[:act_category].to_i
  #   render "home/catalog"
  # end
  # 
  # get :catalogold, :map => 'catalog.php' do
  #   redirect url(:home, :catalog, :act_category => params[:cat]), 301
  # end
  # 
  # get :ac do
  #   @account = Category.new(name: "tryrutl kk")
  #   @account1 = Order.new(description: "пщкеу ущкушпо вкшоеу")
  #   @line1 = Category.new(category: @account, name: "большьк")
  #   @line2 = Category.new(category: @account, name: "малкеиуие уааыдптрф")
  #   @account.save
  #   @line2.save
  #   @line1.save
  #   # @account1.save
  #   render "home/index"
  # end


end
