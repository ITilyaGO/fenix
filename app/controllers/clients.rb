Fenix::App.controllers :clients do
  require 'csv'

  get :index do
    @title = "Clients"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    kc_clients = CabiePio.folder(:clients, :hometowns)
    kc_delivery = CabiePio.folder(:clients, :delivery_towns)
    @kc_clients = kc_clients.flat
    @kc_delivery = kc_delivery.flat
    @kc_towns = KatoAPI.batch(@kc_clients.values.uniq + @kc_delivery.values.uniq)
    city = params[:city]
    kc_filtered = (kc_clients.flatout[city] || []) + (kc_delivery.flatout[city] || [])
    @clients = if !city
      Client.includes(:place).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    else
      Client.includes(:place).order(:updated_at => :desc).where(id: kc_filtered.uniq)
    end
    @pages = (Client.count/pagesize).ceil
    @pages = false if params[:city]
    @r = url(:clients, :index)
    render 'clients/index'
  end

  get :broken do
    @title = "Clients"
    @kc_clients = CabiePio.folder(:clients, :hometowns).flat
    @clients = Client.where.not(id: @kc_clients.keys.map(&:to_i))
    @broken = true
    @kc_delivery = CabiePio.folder(:clients, :delivery_towns).flat
    @kc_towns = KatoAPI.batch(@kc_clients.values.uniq + @kc_delivery.values.uniq)
    render 'clients/index'
  end

  get :orders, :with => :id  do
    @title = "Orders"
    @orders = Order.where(:client_id => params[:id]).order(:updated_at => :desc)
    @client = Client.find(params[:id])
    @kc_orders = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :towns]).flat
    @kc_delivery = CabiePio.all_keys(@orders.map(&:id), folder: [:orders, :delivery_towns]).flat
    @kc_client_hometown = CabiePio.get([:clients, :hometowns], @client.id).data
    @kc_client_delivery = CabiePio.get([:clients, :delivery_towns], @client.id).data
    codes = @kc_orders.values.uniq + @kc_delivery.values.uniq + [@kc_client_hometown, @kc_client_delivery]
    @kc_towns = KatoAPI.batch(codes)

    @r = url(:orders, :index)
    render 'clients/orders'
  end

  get :new do
    @title = "New client"
    @client = Client.new
    render 'clients/new'
  end

  post :create do
    @client = Client.new(params[:client])
    @cats = Client.where(:client_id => nil)
    if @client.save
      code = params[:cabie][:kato_place]
      if Kato.valid? code
        CabiePio.set [:clients, :hometowns], @client.id, code
      end
      dcode = params[:cabie][:kato_delivery]
      dcode = code if dcode.empty?
      if Kato.valid? dcode
        CabiePio.set [:clients, :delivery_towns], @client.id, dcode
      end

      @title = pat(:create_title, :model => "client #{@client.id}")
      flash[:success] = pat(:create_success, :model => 'Client')
      params[:save_and_continue] ? redirect(url(:clients, :index)) : redirect(url(:clients, :edit, :id => @client.id))
    else
      @title = pat(:create_title, :model => 'client')
      flash.now[:error] = pat(:create_error, :model => 'client')
      render 'clients/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "client #{params[:id]}")
    @client = Client.find(params[:id])
    @cats = Client.where(:client_id => nil)
    kc_client = CabiePio.get([:clients, :hometowns], @client.id).data
    @kc_town = KatoAPI.anything(kc_client)
    kc_delivery = CabiePio.get([:clients, :delivery_towns], @client.id).data
    @kc_delivery = KatoAPI.anything(kc_delivery)
    if @client
      render 'clients/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'client', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "client #{params[:id]}")
    @client = Client.find(params[:id])
    if @client
      params[:client][:online_place] = nil if !params[:client][:place_id].blank?
      if @client.update_attributes(params[:client])
        code = params[:cabie][:kato_place]
        if Kato.valid? code
          CabiePio.set [:clients, :hometowns], @client.id, code
        end
        dcode = params[:cabie][:kato_delivery]
        dcode = code if dcode.empty?
        if Kato.valid? dcode
          CabiePio.set [:clients, :delivery_towns], @client.id, dcode
        end
        flash[:success] = pat(:update_success, :model => 'Client', :id => "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:clients, :index)) :
          redirect(url(:clients, :edit, :id => @client.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'client')
        render 'clients/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'client', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Clients"
    client = Client.find(params[:id])
    if client && client.orders.empty?
      if client.destroy
        flash[:success] = pat(:delete_success, :model => 'Client', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'client')
      end
      redirect url(:clients, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'client', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Clients"
    unless params[:client_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'client')
      redirect(url(:clients, :index))
    end
    ids = params[:client_ids].split(',').map(&:strip)
    clients = Client.find(ids)

    if Client.destroy clients
      flash[:success] = pat(:destroy_many_success, :model => 'Clients', :ids => "#{ids.to_sentence}")
    end
    redirect url(:clients, :index)
  end

  get :export, :provides => :csv do
    clients = Client.includes(:place).order(:name)
    isos = CabiePio.folder(:clients, :hometowns).flat
    homes = KatoAPI.batch(isos.values.uniq)
    
    fname = 'clients-' + Time.new.strftime("%d-%m-%Y") + '.csv'
    headers['Content-Disposition'] = "attachment; filename=#{fname}"
    headers['Content-Type'] = "application/vnd.ms-excel"
    output = ''
    output = "\xEF\xBB\xBF" if params.include? :win
    output << CSV.generate(:col_sep => ';') do |csv|
      # csv << %w(id name num)
      clients.each do |item|
        inn = item.inn
        inn.prepend 'ИНН ' if inn&.match? /^[\d\s]+$/
        city = homes[isos[item.id.to_s]]&.model&.name
        csv << [item.id, item.name, item.org, item.tel, item.email, city, inn]
      end
    end
  end
end
