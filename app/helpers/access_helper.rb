Fenix::App.helpers do
  def allow_route?(name)
    project_modules.find {|pmodule| pmodule.name == name }
  end
end
