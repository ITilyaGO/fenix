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
    
    @section.formiz(form)
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
    sec = params[:s]
    @supermodel = KSM::Category.new({})
    @pages = 1
    @section = sec ? KSM::Section.find(sec) : KSM::Section.all.first
    @categories = KSM::Category.all.select{|a| a.section_id == @section.id}.sort_by(&:display)
    @r = url(:products, :index)
    render 'thingcats/cats'
  end

  post :category do
    form = params[:ksm_category]
    @category = KSM::Category.nest if params[:id].nil? || params[:id] == '0000' || params[:clone]
    @category ||= KSM::Category.find(params[:id])
    a = @category
    olcat = a.category_id

    @category.clear_formize(form)
    @category.category_id = nil if form[:category_id].empty?
    @category.section_id = a.category.section_id if a.category_id
    # seed = wonderbox(:categories, :seed) || 0
    # seed += 1
    # wonderbox_set(:categories, { seed: seed }) unless @category.sn
    @category.sn ||= cate_seed_from(a.category_id)
    @category.sn = cate_seed_from(a.category_id) unless a.category_id == olcat
    @category.save
    @category.backsync

    redirect url(:thingcats, :categories, s: @category.section_id)
  end

  get :category, :with => :id do
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @seed = wonderbox(:categories, :seed) || 0
    @category = @supermodel = KSM::Category.find(params[:id])
    @section = @category.section
    @categories = KSM::Category.all.select{|a| a.section_id == @section.id}.sort_by(&:display)
    render 'thingcats/cats'
  end
end