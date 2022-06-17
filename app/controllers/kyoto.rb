Fenix::App.controllers :kyoto do


  get :index do
    render 'kyoto/index'
  end

  get :play do
    @title = "Kyoto - Play"
    render 'kyoto/play'
  end

  get :play, :with => :id do
    @title = "Kyoto - Play"
    render "kyoto/play_#{params[:id]}"
  end

  # get :playtest do
  #   @title = "Kyoto - Play"
  #   render 'kyoto/play_test'
  # end

  get :query do
    @title = "Kyoto - Query"
    render 'kyoto/query'
  end

  get :to_schema do
    redirect_to 'kyoto/schema'
  end

  patch :query do
    @title = "Kyoto - Query Results"
    db = params[:db].to_sym
    key = params[:q]
    smartkey = key.split(/\//).map(&:to_sym)
    match = params[:form][:match].to_sym
    is_clear = params[:clear]
    is_unset = params[:unset]
    cabie = ALL_CABIES[db]

    @data = []
    time = sec do
      if is_clear
        @data << cabie.clear(smartkey)
      elsif is_unset
        @data << cabie.unset(cabie.key_make(key))
      elsif match == :astral
        @data << cabie.astral(key)
      else
        @data = cabie.query key, type: match
      end
    end
    @stat = [Thread.current.inspect, notice_for_time(time)]

    partial 'kyoto/recs'
  end

  # get 'get/:db/:key' do
  #   @title = "Kyoto - Display"
  #   key = params[:key]
  #   cabie_i = ALL_CABIES.values.index(params[:db].to_sym)
  #   cabie = ALL_CABIES.keys[cabie_i]
  #   @data = (cabie.get key)
  #   # .transform_values(&:to_i)

  #   render 'kyoto/index'
  # end

  # get 'display/:db/:key' do
  #   @title = "Kyoto - Display"
  #   key = params[:key]
  #   cabie_i = ALL_CABIES.values.index(params[:db].to_sym)
  #   cabie = ALL_CABIES.keys[cabie_i]
  #   @data = (cabie.all key)
  #   # .transform_values(&:to_i)

  #   render 'kyoto/index'
  # end

  # get 'displayrange/:key' do
  #   @title = "Kyoto - Display"
  #   key = params[:key]
  #   @data = CabieMain.range key

  #   render 'kyoto/index'
  # end

  patch :c_am do
    @title = "Category - Amounts"
    time = sec do
      c_am
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :p_am do
    @title = "Product - Amounts"
    time = sec do
      p_am
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :migrate_towns do
    @title = "Towns - Known"
    time = sec do

      base_pfx = [:towns, :migrate, :known]
      dbg_pfx = [:m, :towns, :migrate, :debug]
      unk_pfx = [:towns, :migrate, :unknown]
      old_pfx = [:towns, :migrate, :old]

      CabiePio.clear base_pfx
      CabiePio.clear unk_pfx
      CabiePio.clear old_pfx

      Place.all.each do |p|
        q = p.name.strip
        qd = q.downcase.gsub('ё', 'е')
        from_index = KyotoCorp::CabieIndex.all(:short, qd).flat
        from_index = KyotoCorp::CabieIndex.all(:full, qd).flat if from_index.empty?

        choosiein = from_index.keys.index(qd)
        if from_index.empty?
          CabiePio.set unk_pfx, p.id, "#{p.name}"
          next
        end
        unless choosiein
          CabiePio.set unk_pfx, p.id, { title: [p.name, qd], debug: from_index.inspect }
          next
        end
        choosie = from_index.values[choosiein]

        CabiePio.set base_pfx, p.id, choosie
        CabiePio.set dbg_pfx, choosie, { id: [p.id, choosie], title: [p.name, from_index.keys[choosiein]], debug: from_index.inspect }
        CabiePio.set old_pfx, p.id, choosie
      end
    
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :known_from_migrate do
    @title = "Towns - Migrate Known"
    time = sec do
      # clear = params[:clear]
      # places = CabiePio.folder(:towns, :migrate, :known).flat

      # base_pfx = [:towns, :known]
      # CabiePio.clear base_pfx if clear


      # places.each do |rec|
      #   town = KatoAPI.anything(rec.key.public).model.name
      #   CabiePio.set base_pfx, rec.key.public, town
      # end
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :account_places_from_migrate do
    @title = "Towns - Migrate Client Places"
    time = sec do
      acc_pfx = [:clients, :hometowns]
      clear = params[:clear]
      CabiePio.clear acc_pfx if clear

      accounts = Client.all
      accounts.each do |account|
        town = CabiePio.get([:towns, :migrate, :known], account.place_id).data
        next unless town
        CabiePio.set acc_pfx, account.id, town
      end
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :client_delivery_from_migrate do
    @title = "Towns - Migrate Client Delivery"
    time = sec do
      acc_pfx = [:clients, :hometowns]
      deli_pfx = [:clients, :delivery_towns]
      kc_home = CabiePio.folder(acc_pfx).flat
      kc_delivery = CabiePio.folder(deli_pfx).flat

      kc_home.each do |client, kato_code|
        next if kc_delivery[client]
        CabiePio.set deli_pfx, client, kato_code
      end
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :order_places_from_migrate do
    @title = "Towns - Migrate Order Places"
    time = sec do
      acc_pfx = [:orders, :towns]
      clear = params[:clear]
      CabiePio.clear acc_pfx if clear

      accounts = Order.all
      accounts.each do |account|
        town = CabiePio.get([:towns, :migrate, :known], account.place_id).data
        next unless town
        CabiePio.set acc_pfx, account.id, town
      end
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :recovery_pull, :with => :db do
    @title = 'Pull cabie from KyotoCorp'
    db = params[:db].to_sym
    @output = [db]
    time = sec do
      resp = KyotoCorp::Client.new(:eag_1).seq(wait:true) do |c|
        c.pull db
      end
      file = resp[:results][db][:snap]
      Cabie.wire(db).restore(file)
    end
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

  patch :recovery_push, :with => :db do
    @title = 'Push cabie to KyotoCorp'
    db = params[:db].to_sym
    @output = [db]
    time = sec do
      file = Cabie.wire(db).backpack.realpath
      resp = KyotoCorp::Client.new(:eag_1).seq do |c|
        c.push db, file
      end
    end
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

  get :status do
    @title = "Kyoto - Status"
    @layers = ALL_CABIES.keys

    @cabies = Cabie.wire

    render 'kyoto/status'
  end

  patch :clear, :with => :db do
    @title = "Kyoto - Clear"

    db = params[:db].to_sym
    time = sec do
      Cabie.wire(db).truncate.create
    end
    @output = [db]
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

  patch :backup, :with => :db do
    @title = 'Isokato backup'
    db = params[:db].to_sym
    @output = [db]
    time = sec do
      @output << Cabie.wire(db).backup.realpath
    end
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

  patch :restore, :with => :db do
    @title = 'Isokato restore'
    db = params[:db].to_sym
    @output = [db]
    time = sec do
      wire = Cabie.wire(db)
      from = wire.fs_prev(ext: Kyoto::BB_EXT)
      @output << wire.restore_db(from)
      @output << from
    end
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

  patch :sn_backup, :with => :db do
    @title = 'Isokato backup'
    db = params[:db].to_sym
    @output = [db]
    time = sec do
      @output << Cabie.wire(db).dump
    end
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

  patch :sn_restore, :with => :db do
    @title = 'Isokato restore'
    db = params[:db].to_sym
    @output = [db]
    time = sec do
      wire = Cabie.wire(db)
      from = wire.fs_prev(ext: Kyoto::SS_EXT)
      @output << wire.restore(from)
      @output << from
    end
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

  patch :close, :with => :db do
    @title = 'Isokato close'
    db = params[:db].to_sym
    act = params[:act]&.to_sym
    time = sec do
      Cabie.wire(db).close
      Cabie.open(db, :read) if act == :read
      Cabie.open(db, :write) if act == :write

      if act == :nosync
        conf = Cabie.species(db)
        conf[:autosync] = false
        Cabie.room db, **conf
        Cabie.open(db, :write)
      end
    end
    @output = [db]
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

  patch :isokato do
    @title = 'Isokato full db'
    time = sec do
      isokato
    end
    @output = [notice_for_time(time)]
    
    partial 'kyoto/notice'
  end


  patch :isokato_clean do
    @title = 'Isokato cleanup'
    time = sec do
      isokato_clean
    end
    @output = [notice_for_time(time)]
    
    partial 'kyoto/notice'
  end

  patch :isokato_sim_crc do
    @title = 'Isokato cleanup crc'
    time = sec do
      isokato_sim_crc
    end
    @output = [notice_for_time(time)]
    
    partial 'kyoto/notice'
  end

  patch :isokato_index do
    @title = 'Isokato index'
    time = sec do
      isokato_index
    end
    @output = [notice_for_time(time)]
    
    partial 'kyoto/notice'
  end

  patch :isokato_log do
    @title = 'Isokato log'
    @output = `tail -50 vendor/isokato/log/kato.log`.lines
    
    partial 'kyoto/notice'
  end

  patch :sample do
    @title = 'Isokato dump'
    time = sec do
      @regions = KatoAPI.regions
      @towns = KatoAPI.towns
      @dst = KatoAPI.districts(nil)
      mrs = Marshal.dump({t:@towns, r:@regions, d:@dst})
      umrs = Marshal.load mrs
      # j = {t:@towns, r:@regions, d:@dst}.to_json
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :bm do
    @title = 'Isokato bm'
    @output = []
    # time = sec do
    #   MemoryProfiler.start
    #   1000.times do
    #     CabieKato.get [:plc], 'RU-ADX-GYGN-CERMSK'
    #   end
    #   @res1 = MemoryProfiler.stop
    #   # @regions = KatoAPI.regions
    #   # @towns = KatoAPI.towns
    #   # @dst = KatoAPI.districts(nil)
    #   # mrs = Marshal.dump({t:@towns, r:@regions, d:@dst})
    #   # umrs = Marshal.load mrs
    #   # # j = {t:@towns, r:@regions, d:@dst}.to_json
    # end
    # @output << '1000 get' << notice_for_time(time)

    # time1 = sec do
    #   1.times do
    #     l = CabieLayerX.new(:isokato, file: Padrino.root('db/cabs', 'isokato.kct')).open(:read)
    #     l.get [:plc], 'RU-ADX-GYGN-CERMSK'
    #   end
    # end
    # @output << '1000 open and get' << notice_for_time(time1)

    # time2 = sec do
    #   10.times do
    #     l = `ps -o sess= -p #{$$}`.to_i
    #   end
    # end
    # @output << '1000 ps' << notice_for_time(time2)

    time3 = sec do
      # RubyProf.start
      # MemoryProfiler.start
      klx = CabieLayerX.new(:isokato, file: Padrino.root('db/cabs', 'isokato.kct')).open(:read)
      ilx = CabieLayerX.new(:index, file: Padrino.root('db/cabs', 'isokato_index.kct')).open(:read)
      api = KatoAPI2.new db: klx, index: ilx
      KatoAPI.startup db: klx, index: ilx
      title = "Towns - Stats"
      5.times do
        regions = api.regions
        towns = api.districts nil
        t2 = api.regions.flat
        twns = api.towns.flat.transform_values{|v|v[:name]}

        regions = KatoAPI.regions
        towns = KatoAPI.districts nil
        t2 = KatoAPI.regions.flat
        twns = KatoAPI.towns.flat.transform_values{|v|v[:name]}
      end
      @output << klx.wire.mode << ilx.wire.mode
      klx.wire.close
      ilx.wire.close

      # @res = RubyProf.stop
      # @res2 = MemoryProfiler.stop
    end
    # rs = StringIO.new
    # RubyProf::GraphPrinter.new(@res).print(rs)
    # @res1.pretty_print(rs)
    # @res2.pretty_print(rs)
    # @pre = [rs.string]

    partial 'kyoto/notice'
  end

  patch :threads do
    @title = 'Threads'
    # Thread.kill($bt)
    time = sec do
      @t = Thread.list
    end
    @output = [notice_for_time(time)]
    @output << ['Main', Thread.main.inspect]
    @output += @t.map{|thr| thr.inspect}

    partial 'kyoto/notice'
  end

  post :migration do
    input = params[:transport]
    input.each do |id, data|
      next if data.to_sym == :none
      CabiePio.set [:m, :migrate, :transport], id, data.to_sym
    end

    redirect_to 'kyoto/table/4'
  end

  get :table, :with => :id do
    @title = 'Migration table'
    @datatable = case n = params[:id].to_i
    when 4
      Client.all.map do |c|
        guess_transport(c).values << c.name << c.shipping_company << c.comment
      end
    end
    @mg = CabiePio.folder(:m, :migrate, :transport).flat.trans(:to_i)

    render 'kyoto/table'
  end


end