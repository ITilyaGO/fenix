Fenix::App.controllers :thingcats do
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

  get :sections do
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @seed = wonderbox(:sections, :seed) || 0
    @sections = KSM::Section.all.sort_by(&:name)
    @supermodel = KSM::Section.new({})
    @pages = 1
    @r = url(:products, :index)
    render 'thingcats/sections'
  end

  post :section do
    form = params[:ksm_section]
    @section = KSM::Section.nest if params[:id].nil? || params[:id] == '0000' || params[:clone]
    @section ||= KSM::Section.find(params[:id])
    
    @section.fill **KSM::Section.formize(form), merge: true
    seed = wonderbox(:sections, :seed) || 0
    seed += 1
    wonderbox_set(:sections, { seed: seed }) unless @section.sn
    @section.sn ||= seed
    @section.save

    redirect url(:thingcats, :sections)
  end

  get :section, :with => :id do
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @seed = wonderbox(:sections, :seed) || 0
    @sections = KSM::Section.all.sort_by(&:name)
    @section = @supermodel = KSM::Section.find(params[:id])
    @pages = 1
    @r = url(:products, :index)
    render 'thingcats/sections'
  end
  

  get :categories do
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @seed = wonderbox(:categories, :seed) || 0
    @categories = KSM::Category.all.sort_by(&:display)
    @supermodel = KSM::Category.new({})
    @pages = 1
    @r = url(:products, :index)
    render 'thingcats/cats'
  end

  post :category do
    form = params[:ksm_category]
    @category = KSM::Category.nest if params[:id].nil? || params[:id] == '0000' || params[:clone]
    @category ||= KSM::Category.find(params[:id])

    @category.fill **KSM::Category.formize(form), merge: true
    @category.category_id = nil if form[:category_id].empty?
    # seed = wonderbox(:categories, :seed) || 0
    # seed += 1
    # wonderbox_set(:categories, { seed: seed }) unless @category.sn
    @category.sn ||= cate_seed_from(@category.category_id)
    @category.save

    redirect url(:thingcats, :categories)
  end

  get :category, :with => :id do
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @seed = wonderbox(:categories, :seed) || 0
    @categories = KSM::Category.all.sort_by(&:name)
    @category = @supermodel = KSM::Category.find(params[:id])
    @pages = 1
    @r = url(:products, :index)
    render 'thingcats/cats'
  end
end