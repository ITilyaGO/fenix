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
      account ||= Account.find(1)
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

  get :power do
    render "/sessions/power", nil, :layout => false
  end

  get :power_codes, :with => :id do
    @id = params[:id]
    render "/sessions/codes", :layout => false
  end

  post :power do
    unless KSM::Power.all.any?
      pow = KSM::Power.nest
      pow.name = params[:name]
      pow.auth = Secure::Base32.random 32
      pow.save
      redirect url(:sessions, :power_codes, id: pow.id)
    end

    pow  = KSM::Power.find_by_name(params[:name])
    pass = pow && params[:password] == Secure.totp(Secure::Base32.decode(pow.auth))
    dev  = Padrino.env == :development && params[:bypass]
    if pass || dev
      account = Account.find_by_email(params[:email])
      account ||= Account.find(1)
      set_current_account(account)
      redirect url(:home, :index)
    else
      flash.now[:error] = pat('login.error')
      render "/sessions/power", nil, :layout => false
    end
  end

  get :codes, :with => :id, :provides => :svg do
    pow = KSM::Power.find(params[:id])
    return nil unless pow.exist?
    qrcode = RQRCode::QRCode.new("otpauth://totp/#{pow.name}?secret=#{pow.auth}&issuer=PioPower")
    qrcode.as_svg
  end
end
