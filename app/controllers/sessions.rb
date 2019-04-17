Fenix::App.controllers :sessions do
  get :new do
    render "/sessions/new", nil, :layout => false
  end

  post :create do
    if account = Account.authenticate(params[:email], params[:password])
      set_current_account(account)
      redirect url(:home, :index)
    elsif Padrino.env == :development && params[:bypass]
      account = Account.find_by_email(params[:email])
      set_current_account(account)
      redirect url(:home, :index)
    else
      params[:email] = h(params[:email])
      flash.now[:error] = pat('login.error')
      render "/sessions/new", nil, :layout => false
    end
  end

  delete :destroy do
    set_current_account(nil)
    redirect url(:sessions, :new)
  end
end
