Fenix::App.helpers do
  def allow_route?(name)
    project_modules.find {|pmodule| pmodule.name == name }
  end

  def role_is?(name)
    (current_account.role.to_sym rescue :any).equal? name
  end
end
