Fenix::App.controllers :online do
  CLIENTS_FILE = 'db/clients.csv'
  
  after do
    ActiveRecord::Base.clear_active_connections!
  end

  get :list do
    @title = "Categories"
    @accounts = Online::Account.all.order(:city => :asc)
    render 'online/list'
  end
  
  get :orders do
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @orders = Online::Order.includes(:account).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    order_ids = Online::Order.order(:updated_at => :desc).offset((@page-1)*pagesize).pluck(:id).take(pagesize)
    @imp_ids = Order.where(:online_id => order_ids).pluck(:online_id)
    @pages = (Online::Order.count/pagesize).ceil
    @r = url(:online, :orders)
    render "online/orders"
  end

  get :sync, :with => :name do
    @table = params[:name]
    case params[:name]
    when "product"
      Product.sync
    when "category"
      Category.sync
    when "place"
      Place.sync
    when "client"
      Client.sync
    when "all"
      Product.sync
      Category.sync
      Place.sync
      Client.sync
    else
      @table = "None"
    end
    render "online/sync"
  end

  get :sync_status do
    @status = []
    p = Product.order(:id => :desc).first
    op = Online::Product.find(p.id) rescue nil if p
    @status << { :name => 'Продукты', :synced => !p.nil? && !op.nil? && p.updated_at == op.updated_at, :u => "product" }
    cat = Category.order(:id => :desc).first
    ocat = Online::Category.find(cat.id) rescue nil if cat
    @status << { :name => 'Категории', :synced => !cat.nil? && !ocat.nil? && cat.updated_at == ocat.updated_at, :u => "category" }
    # pl = Place.order(:updated_at => :desc).first
    # opl = Online::Place.find(pl.id) rescue nil if pl
    @status << { :name => 'Города', :synced => false, :u => "place", :d => true }
    @status << { :name => 'Клиенты', :synced => false, :u => "client", :d => true }
    render "online/sync_status"
  end
  
  get :csv do
    @accounts = CSV.read(CLIENTS_FILE, { :col_sep => ';'})
    render 'online/csv'
  end
  
  get :new_cities do
    @cities = []
    CSV.foreach(CLIENTS_FILE, { :col_sep => ';', :headers => true }) do |row|
      city = Place.find_by(:name => row[0])
      @cities << row[0] if city.nil?
    end
    @cities = @cities.uniq
    render 'online/new_cities'
  end
  
  get :pre do
    # upsert = Upsert.new connection, 'customers'
    # @d1 = CSV.read('tmp/clients.csv', { :col_sep => ';' })
    
    # Online::Account.all.each do |account|
    #   city = Place.where(:name => account.city).first
    #   # TODO: we cant add new places since db syncs sometimes
    #   # if city.nil?
    #   #   c = Place.create({ :name => account.city, :city_type => 1 })
    #   #   city = c.id
    #   # end
    #   # dup = {:online_id => account.id, :name => account.name, :tel => account.tel, :place => city, :email => account.email, :org => account.org}
    #   # Client.create(dup)
    # end
  
    @a = []
    CSV.foreach(CLIENTS_FILE, { :col_sep => ';', :headers => true }) do |row|
      # word.split(/[\s,']/)
      # phones = row[3].split(/[.,;\/]/)
      # phones.each do |p|
      #   pp = p.gsub(/[^0-9]/, "")
      #   Client.where('lower(name) LIKE ?', params[:q])
      # end
      # phonenumber.to_s.gsub(/[^0-9]/, "")
      
      accounts = Online::Account.where(:city => row[0])
      city = Place.find_by(:name => row[0])
       # || Place.create(:name => row[0])
      # city = Place.create(:name => row[0]) if !city
      c = { :name => row[1], :tel => row[3], :inn => row[2], :place => city, :email => 'a@a.aa', :comment => row[4], :accounts => accounts }
      @a << c
      # c.save
      # case row[:contract_start_year]
      # when 1
      #   row[:customer_key] = # SNIP
      # when 2
      #   # SNIP
      # else
      #   if row[:original_row_type] == 'CUSTOMER'
      #     # SNIP
      #   end
      # end
      # upsert.row(row) if row[:compliance_check] == '1'
    end
    render "online/pre"
  end

  get :merge, :with => :off do
    # upsert = Upsert.new connection, 'customers'
    # @d1 = CSV.read('tmp/clients.csv', { :col_sep => ';' })
    off = params[:off].to_i == 1
    
    @cities = []
    CSV.foreach(CLIENTS_FILE, { :col_sep => ';', :headers => true }) do |row|
      city = Place.find_by(:name => row[0])
      @cities << row[0] if city.nil?
    end
    @cities.uniq.each do |c|
      Online::Place.create(:name => c, :city_type => 1)
    end
    Place.sync

    CSV.foreach(CLIENTS_FILE, { :col_sep => ';', :headers => true }) do |row|
      # word.split(/[\s,']/)
      # phones = row[3].split(/[.,;\/]/)
      # phones.each do |p|
      #   pp = p.gsub(/[^0-9]/, "")
      #   Client.where('lower(name) LIKE ?', params[:q])
      # end
      # phonenumber.to_s.gsub(/[^0-9]/, "")
      
      city = Place.find_by(:name => row[0])
      next if !city
      # city = Place.create(:name => row[0]) if !city
      if row[6].blank?
        next if !off
        c = Client.new
      else
        c = Client.find_by(:online_id => row[6])
      end
      next if c.nil?
      c.name = row[1]
      c.inn = row[2]
      c.tel = row[3]
      c.place = city
      c.comment = row[4]
      c.email = row[5]
      # c = Clicent.new(:name => row[1], :tel => row[3], :inn => row[2], :place => city, :email => 'a@a.aa', :comment => row[4])
      c.save
      # case row[:contract_start_year]
      # when 1
      #   row[:customer_key] = # SNIP
      # when 2
      #   # SNIP
      # else
      #   if row[:original_row_type] == 'CUSTOMER'
      #     # SNIP
      #   end
      # end
      # upsert.row(row) if row[:compliance_check] == '1'
    end
    render "home/index"
  end

end