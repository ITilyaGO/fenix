Fenix::App.controllers :riot, :map => "/riot/tags/" do

  get :index, :with => ':name.tag' do
    Slim::Engine.options[:pretty] = true
    render "riot/#{params[:name]}", :layout => false
  end

end