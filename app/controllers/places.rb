Fenix::App.controllers :places do
  get :index do
    @title = "Places"
    @places = Place.all
    @regions = Region.all
    render 'places/index'
  end
end
