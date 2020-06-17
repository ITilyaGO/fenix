Fenix::App.controllers :places do
  get :index do
    @title = "Places"
    sort = params[:sort] || "id"
    @places = Place.all.order(sort)
    @regions = Region.all
    @kc_places = CabiePio.folder(:towns, :migrate, :known).flat
    @kc_towns = KatoAPI.batch(@kc_places.values)
    render 'places/index'
  end

  get :stl_global, :provides => :json do
    q = params[:q].downcase
    places_global(q, 10).to_json
  end
end
