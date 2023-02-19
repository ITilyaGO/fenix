Fenix::App.controllers :riot, :map => "/xriot/tags/" do

  get :index, :with => ':name.tag' do
    Slim::Engine.options[:pretty] = true
    render "riot/#{params[:name]}", :layout => false
  end

  get :index, :with => ':dir/:name.tag' do
    Slim::Engine.options[:pretty] = true
    render "riot/#{params[:dir]}/#{params[:name]}", :layout => false
  end

end