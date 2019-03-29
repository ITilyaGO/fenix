Fenix::App.controllers :regions do
  get :index do
    @title = "Regions"
    @regions = Region.all
    @managers = Manager.all
    render 'regions/index'
  end

  get :new do
    @title = "New region"
    @region = Region.new
    render 'regions/new'
  end

  post :create do
    @region = Region.new(params[:region])
    if @region.save
      @title = pat(:create_title, :model => "region #{@region.id}")
      flash[:success] = pat(:create_success, :model => 'Region')
      params[:save_and_continue] ?
        redirect(url(:regions, :index)) :
        redirect(url(:regions, :edit, :id => @region.id))
    else
      @title = pat(:create_title, :model => 'region')
      flash.now[:error] = pat(:create_error, :model => 'region')
      render 'regions/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "region #{params[:id]}")
    @region = Region.find(params[:id])
    if @region
      render 'regions/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'region', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "region #{params[:id]}")
    @region = Region.find(params[:id])
    if @region
      if @region.update_attributes(params[:region])
        flash[:success] = pat(:update_success, :model => 'Region', :id => "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:regions, :index)) :
          redirect(url(:regions, :edit, :id => @region.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'region')
        render 'regions/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'region', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :assign do
    region = Region.find(params[:region_id])

    places = params[:place_ids].split(',').map(&:strip)
    places.each do |p|
      place = Place.find(p)
      place.region_id = region.id
      place.save
    end

    redirect(url(:places, :index))
  end

  delete :destroy, :with => :id do
    region = Region.find(params[:id])
    if region
      if region.destroy
        flash[:success] = pat(:delete_success, :model => 'Region', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'region')
      end
      redirect url(:regions, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'region', :id => "#{params[:id]}")
      halt 404
    end
  end
end
