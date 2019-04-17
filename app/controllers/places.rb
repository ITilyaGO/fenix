Fenix::App.controllers :places do
  get :index do
    @title = "Places"
    sort = params[:sort] || "id"
    @places = Place.all.order(sort)
    @regions = Region.all
    render 'places/index'
  end
end
