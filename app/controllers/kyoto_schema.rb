Fenix::App.controllers :kyoto_schema, :map => 'kyoto/schema' do
  get :index do
    @schema = wonderbox(:schema)
    @avail = 13
    render 'kyoto/schema'
  end

  patch :up, :with => :id do
    @title = "Migrate #{params[:id]}"
    force = params[:force]
    time = sec do
      case n = params[:id].to_i
      when 1
        # migrate_1
      when 2
        complexity_init
        complexity_up_job(force:force)
      when 3
        timeline_up(force:force)
      when 4
        transport_up(force:force)
      when 5
        sticker_history_005_up
      when 6
        stock_006_up(force:force)
      when 7
        sticker_day_007_up
      when 8
        create_archetypes_008_up(force:force)
      when 9
        stickday_009_up(force:force)
      when 10
        order_status_010_up(force:force)
      when 11
        order_destocks_011_up(force:force)
      when 12
        draft_status_012_up
      when
        products_to_things_013_up
      end
      
      wonderbox_set(:schema, n)
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :down, :with => :id do
    @title = "Migrate down #{params[:id]}"
    force = params[:force] || true
    time = sec do
      case n = params[:id].to_i
      when 4
        transport_down(force:force)
      end
      
      wonderbox_set(:schema, n.pred)
    end
    @output = [notice_for_time(time)]

    partial 'kyoto/notice'
  end

  patch :preview, :with => :id do
    @title = "Migrate preview #{params[:id]}"
    force = params[:force]
    @output = []
    time = sec do
      case n = params[:id].to_i
      when 4
        @pre = [transport_preview]
      end
    end
    @output << notice_for_time(time)

    partial 'kyoto/notice'
  end

end
