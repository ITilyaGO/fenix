Front::App.controllers :riot, :map => "/tags/" do

  get :index, :with => ':name.tag' do
    Slim::Engine.options[:pretty] = true
    render params[:name], :views => Padrino.root('front', 'riot'), :layout => false
  end

  get :index, :with => ':dir/:name.tag' do
    Slim::Engine.options[:pretty] = true
    render "#{params[:dir]}/#{params[:name]}", :views => Padrino.root('front', 'riot'), :layout => false
  end

end