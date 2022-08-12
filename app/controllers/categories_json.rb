Fenix::App.controllers :categories do

  post :plainlist, :provides => :json do
    cats_plainlist.to_json
  end
end