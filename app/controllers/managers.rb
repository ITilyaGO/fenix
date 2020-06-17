Fenix::App.controllers :managers do
  get :index do
    @title = "Managers"
    @managers = Manager.all
    render 'managers/index'
  end

  get :new do
    @title = "New manager"
    @manager = Manager.new
    @points = []
    render 'managers/new'
  end

  post :create do
    @manager = Manager.new(params[:manager])
    if @manager.save
      @title = pat(:create_title, :model => "manager #{@manager.id}")
      flash[:success] = pat(:create_success, :model => 'Manager')
      params[:save_and_continue] ?
        redirect(url(:managers, :index)) :
        redirect(url(:managers, :edit, :id => @manager.id))
    else
      @title = pat(:create_title, :model => 'manager')
      flash.now[:error] = pat(:create_error, :model => 'manager')
      render 'managers/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "manager #{params[:id]}")
    @manager = Manager.find(params[:id])
    if @manager
      @points = CabiePio.get([:m, :managers, :geo_poss], @manager.id).data || []
      @kc_towns = KatoAPI.batch(@points)

      render 'managers/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'manager', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "manager #{params[:id]}")
    @manager = Manager.find(params[:id])
    if @manager
      if @manager.update_attributes(params[:manager])
        codes = params[:cabie][:kato_place].lines.map(&:chomp)
        results = KatoAPI.batch(codes)

        junk = CabiePio.get([:m, :managers, :geo_poss], @manager.id).data || []
        junk.each do |j|
          junk_data = CabiePio.get([:towns, :managers], j).data.to_i
          CabiePio.unset([:towns, :managers], j) if junk_data == @manager.id
        end
        points = []
        results.each do |c, rec|
          next if rec.blank?
          CabiePio.set [:towns, :managers], c, @manager.id
          points << c
        end
        CabiePio.set [:m, :managers, :geo_poss], @manager.id, points


        flash[:success] = pat(:update_success, :model => 'Manager', :id => "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:managers, :index)) :
          redirect(url(:managers, :edit, :id => @manager.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'manager')
        render 'managers/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'manager', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :assign do
    manager = Manager.find(params[:manager_id])

    regions = params[:region_ids].split(',').map(&:strip)
    regions.each do |r|
      region = Region.find(r)
      region.manager_id = manager.id
      region.save
    end

    redirect(url(:regions, :index))
  end
end
