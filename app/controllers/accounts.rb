Fenix::App.controllers :accounts do
  get :index do
    @title = "Accounts"
    @accounts = Account.all
    render 'accounts/index'
  end

  get :new do
    @title = "New account"
    @account = Account.new
    @sections = KSM::Section.all
    render 'accounts/new'
  end

  post :create do
    params[:account].delete(:role) if params[:account][:role].empty?
    @account = Account.new(params[:account])
    @sections = KSM::Section.all
    if @account.save
      if params[:save_ac]
        role_hash = combine_rights(params[:account][:role].to_sym, params[:secta]&.keys&.map(&:to_i))
        kc_save_box_ac(@account.id, role_hash)
      end
      @title = pat(:create_title, :model => "account #{@account.id}")
      flash[:success] = pat(:create_success, :model => 'Account')
      params[:save_and_continue] ? redirect(url(:accounts, :index)) : redirect(url(:accounts, :edit, :id => @account.id))
    else
      @title = pat(:create_title, :model => 'account')
      flash.now[:error] = pat(:create_error, :model => 'account')
      render 'accounts/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "account #{params[:id]}")
    @account = Account.find(params[:id])
    @account.current = current_account.id
    @cats = Account.where(:account_id => nil)
    @sections = KSM::Section.all
    if @account
      render 'accounts/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'account', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "account #{params[:id]}")
    @account = Account.find(params[:id])
    @sections = KSM::Section.all
    if @account
      params[:account].delete(:role) if params[:account][:role].empty?
      if @account.update_attributes(params[:account])
        if params[:save_ac]
          role_hash = combine_rights(params[:account][:role].to_sym, params[:secta]&.keys&.map(&:to_i))
          kc_save_box_ac(@account.id, role_hash)
        end
        flash[:success] = pat(:update_success, :model => 'Account', :id => "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:accounts, :index)) :
          redirect(url(:accounts, :edit, :id => @account.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'account')
        render 'accounts/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'account', :id => "#{params[:id]}")
      halt 404
    end
  end

  get :control, :with => :id do
    @account = Account.find(params[:id])
    @sections = KSM::Section.all

    render 'accounts/control'
  end

end
