Fenix::App.controllers :things do
  get :index do
    redirect url(:products, :index2)
    @title = "Products"
    pagesize = PAGESIZE
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @products = Product.all.includes(:category).order(:updated_at => :desc).offset((@page-1)*pagesize).take(pagesize)
    @pages = (Product.count/pagesize).ceil
    @r = url(:products, :index)
    render 'products/index'
  end

  get :table do
    @title = t 'tit.products.list'
    pagesize = (params[:pagesize] || 100).to_i

    products_by_filters(params)

    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)
    @pages = (@products.size / pagesize.to_f).ceil
    @page = !params[:page].nil? ? params[:page].to_i : 1
    @page = 1 if @page > @pages
    start_pos = ((@page - 1) * pagesize)
    @products = @products[start_pos..(start_pos + (pagesize - 1))] || [] if @page != 0

    @cats = KSM::Category.toplevel.sort_by(&:wfindex)

    @ccat = none_to_nil params[:cat]
    @place = none_to_nil params[:place]

    @r = url(:products, :index)
    render 'things/table'
  end

  get :index2 do
    @title = t 'tit.products.list'
    @product = Product.new(id: -1)
    @xproduct = {}
    @cats = Category.where(category: nil).order(:index => :asc)
    @categories = Category.all.includes(:category)

    render 'products/listform'
  end

  get :edit, :with => :id do
    @title = t 'tit.products.list'
    @product = Product.find(params[:id])
    @kc_place = KatoAPI.anything(@product.place_id)
    @xproduct = SL::Product.new @product.id
    linkage = Stock::Linkage.find(@product.id)
    @arch = KSM::Archetype.find linkage.body
    @cats = KSM::Category.toplevel.sort_by(&:wfindex)
    # @categories = Category.all.includes(:category)

    townfilter = @product.place_id
    ccat = @product.category_id
    @product.category_id = params[:cat] unless @product.exist?
    if townfilter and ccat
      @products = Product.which(townfilter).select{ |a| a.category_id == ccat }.sort_by(&:cindex)
    else
      ids = wonderbox(:things_by_date).reverse
      @products = Product.find_all(ids).sort_by{ |a| ids.index(a.id) }
      @notice = 'Город или категория не выбраны - показаны последние изменения'
    end
    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)
    @squadconf = @product.serializable_hash
    @product.id = '0000' if params[:clone]

    @ccat = ccat
    @place = townfilter

    render 'things/listform'
  end

  put :update, :with => :id do
    tid = params[:id]
    @product = Product.find tid
    @product = Product.nest if tid == '0000' || params[:clone]
    @product.origin = tid if params[:clone]
    preduct = @product.dup
    form = params[:product]
    @product.clear_formize(form)
    @product.area_movement preduct
    @product.sn ||= thing_glob_seed
    @product.saved_by @current_account
    thing_to_top @product.id
    update_autodic @product
    xproduct = SL::Product.new @product.id
    xproduct.raw = params[:raw]
    xproduct.save_links
    @product.backsync if @product.global?
    known_cities_add @product.place_id
    OrderAssist.reset_products_list
    ProductAssist.otree_job(otree_compare @product, preduct)
    if @product
      if true
        flash[:success] = pat(:update_success, :model => 'Product', :id =>  "#{@product.id}")
        params[:save_and_continue] ?
          redirect(url(:things, :index)) :
          redirect(url(:things, :edit, :id => @product.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'product')
        render 'products/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'product', :id => "#{params[:id]}")
      halt 404
    end
  end

  get :transfer do
    render 'things/transfer'
  end

  post :transfer do
    file = params[:file]
    tempfile = file[:tempfile]
    lines = CSV.read(tempfile.path, :headers => :first_row, encoding: 'bom|utf-8',col_sep: ';', header_converters: lambda { |a| a.to_sym }) rescue []
    lines = CSV.read(tempfile.path, :headers => :first_row, encoding: 'windows-1251:utf-8', col_sep: ';', header_converters: lambda { |a| a.to_sym }) if lines.size == 0 rescue []
    is_new_product_id = ['0000', 'new']
    @counter = 0
    @saved_counter = 0
    @warning_counter = 0
    @error_lines = []
    @products = []
    lines.each_with_index do |line, l_index|
      product = Product.find(id = line[:id]) unless id&.blank? || id.eql?('уин')
      next if id.eql?('уин')
      @warning_counter += 1
      if id == '' || id.nil? || id.empty?
        line_error = ['Поле ID пусто', line]
      elsif id&.length != 8 && !is_new_product_id.include?(id)
        line_error = ['Длинна ID не равна 8', line]
      end
      if line_error
        @error_lines << ["Строка: #{ l_index + 2 }", (@product ? 'Частично сохранено' : 'Не сохранено'), *line_error]
        next
      end

      begin
        item = {
          id: line[:id],
          name: line[:type],
          look: line[:view],
          category_id: line[:category].split(':').first.delete(' '),
          place_id: line[:place].split(':').first.delete(' '),
          price: line[:price],
          # sn: line[:sku].split('.').last,
          desc: line[:desc],
          corel: line[:corel],
          art: line[:art],
          discount: line[:discount],
          dim_weight: line[:weight],
          dim_height: line[:height],
          dim_width: line[:width],
          dim_length: line[:length],
          windex: line[:windex],
          lotof: line[:lotof],
          lotof_mfg: line[:lotof_mfg],
          tagname: line[:tagname],
          bbid: line[:bb]
          # barcode: line[:barcode]
        }

        @raw = {
          arn: line[:bb] || '',
          sticker: line[:sticker],
          multi: line[:multi]
        }

        product.formiz item.clone
        if params[:preview].nil?
          tid = line[:id]
          @product = Product.find tid
          @product = Product.nest if is_new_product_id.include?(tid)
          preduct = @product.dup
          @product.clear_formize(item)
          @product.area_movement preduct
          @product.sn ||= thing_glob_seed
          @product.saved_by @current_account
          thing_to_top @product.id
          update_autodic @product
          xproduct = SL::Product.new @product.id
          xproduct.raw = @raw
          xproduct.save_links
          @product.backsync if @product.global?
          known_cities_add @product.place_id
          OrderAssist.reset_products_list
          ProductAssist.otree_job(otree_compare @product, preduct)
        end

        @warning_counter -= 1
      rescue ActiveRecord::StatementInvalid => e
        line_error = [e.message, line]
      # rescue NoMethodError => e
      #   line_error = ['Ошибка метода', e.message, line]
      rescue
        line_error = ['Не известная ошибка', line]
      end
      @error_lines << ["Строка: #{ l_index + 2 }", (@product ? 'Частично сохранено' : 'Не сохранено'), *line_error] if line_error

      @products << [(@product || product), @raw || {}, is_new_product_id.include?(id)]
      @saved_counter += 1 if @product
      @counter += 1
    end

    tempfile.unlink

    render 'things/transfer'
  end

  get :priceedit do
    @title = 'Редактирование цен продуктов'
    products_by_filters(params)
    @products_values = {}
    @products_saved = {}
    @r = url(:things, :priceedit)
    @ra = [:things, :priceedit]
    render 'things/priceedit'
  end

  post :priceedit do
    @title = 'Редактирование цен продуктов'

    data = params[:products]
    data = data.map do |k, v|
      vi = v.to_i
      [k, vi.to_s == v ? vi : nil]
    end.to_h
    @products = Product.find_all(data.keys)
    @products.sort_by!{ |p| data.find_index{ |k, v| k == p.id } }

    @products_saved = {}
    if params[:save]
      @products.each do |prod|
        new_price = data[prod.id]
        next if !new_price || prod.price == new_price
        prod.price = new_price
        prod.saved_by @current_account
        prod.backsync if prod.global?
        @products_saved[prod.id] = 1
      end
      params[:price_filter] = nil
      params[:formula] = nil
    end

    filter_list = (params[:price_filter] || '').split(/[^\d]/).compact
    search_list = (params[:name_filter] || '').downcase.split(/[\s,.'"()-]/).compact
    no_price_filter = filter_list.size == 0
    no_search_filter = search_list.size == 0

    @products_values = {}
    @products.each do |prod|
      begin
        p_dn = prod.displayname.downcase unless no_search_filter
        if (no_price_filter || filter_list.include?(prod.price.to_s)) && (no_search_filter || search_list.all?{ |w| p_dn.include?(w) })
          val = params[:formula]&.gsub(/[^\d]/, '')
        else
          val = nil
        end
      rescue Exception => exc
        val = exc
      end
      @products_values[prod.id] = val
    end

    @products.select!{ |p| @products_values[p.id] } if params[:filter]

    if params[:filter]
      params[:price_filter] = nil
      params[:name_filter] = nil
    end

    @r = url(:things, :priceedit)
    @ra = [:things, :priceedit]
    render 'things/priceedit'
  end

  get :multiedit do
    @title = 'Мультиредактор продукции'

    @cats = KSM::Category.toplevel.sort_by(&:wfindex)

    products_by_filters(params)

    @ccat = none_to_nil params[:cat]
    @place = none_to_nil params[:place]

    @fields = { name: 'Название', look: 'Вид', category_id: 'ID Категории',
      place_id: 'ID Город', price: 'Цена', desc: 'Описание', corel: 'Собрание', art: 'Артикул',
      discount: 'Скидка', dim_weight: 'Вес', dim_height: 'Высота', dim_width: 'Ширина', dim_length: 'Длинна',
      windex: 'Индекс', lotof: 'Кратность', lotof_mfg: 'Производство', tagname: 'Тег' , arn: 'Склад',
      sticker: 'Стикер', multi: 'Множитель', pit: 'Скрыть город', ignored: 'Удалено'
    }

    @r = url(:things, :multiedit)
    @ra = [:things, :multiedit]
    render 'products/multiedit'
  end

  post :multiedit_save do
    content_type 'text/event-stream'
    stream :keep_open do |out|
      begin
        data = JSON.parse(params[:data])
        products = Product.find_all(data.keys)

        other_keys = ['multi', 'arn', 'sticker', 'pit', 'ignored']
        value_guard = {
          'name' => :to_s, 'look' => :to_s, 'category_id' => :to_s, 'place_id' => :to_s,
          'price' => :to_i, 'desc' => :to_s, 'corel' => :to_s, 'art' => :to_s, 'discount' => :to_i,
          'dim_weight' => :to_f, 'dim_height' => :to_f, 'dim_width' => :to_f, 'dim_length' => :to_f,
          'windex' => :to_s, 'lotof' => :to_i, 'lotof_mfg' => :to_i, 'tagname' => :to_s
        }

        products_count = products.size
        out << "§MPROD:#{ products_count.to_s }"

        prew_time_now = Time.now.to_f

        products.each_with_index do |prod, p_index|
          begin
            line = data[prod.id]
            raw = {
              arn: line['arn']&.strip&.downcase,
              sticker: line['sticker']&.to_f,
              multi: line['multi']&.to_i
            }.compact
            pit = empty_to_nil(line['pit'])&.to_i
            ignored = empty_to_nil(line['ignored'])&.to_i
            other_keys.each{ |k| line.delete(k) }

            preduct = prod.dup
            line.each do |k, v|
              next if v.empty?
              v = v&.strip.send(value_guard[k])
              next if prod.send("#{ k }") == v
              prod.send("#{ k }=", v)
            end
            
            prod.settings[:pi] = pit == 1 ? 1 : 0 if (pit && prod.settings&.fetch(:pi, 0) != pit)
            prod.ignored = ignored == 1 ? 1 : 0

            prod.area_movement preduct
            # prod.sn ||= thing_glob_seed
            prod.saved_by @current_account
            thing_to_top prod.id
            update_autodic prod

            if raw[:arn]
              CabiePio.set([:product, :archetype], prod.id, raw[:arn]) unless raw[:arn].empty?
              CabiePio.unset([:product, :archetype], prod.id) if raw[:arn].empty?
            end

            if raw[:multi]
              CabiePio.set([:product, :archetype_multi], prod.id, raw[:multi]) if raw[:multi] > 1
              CabiePio.unset([:product, :archetype_multi], prod.id) unless raw[:multi] > 1
            end

            if raw[:sticker]
              CabiePio.set([:products, :sticker], prod.id, raw[:sticker]) if raw[:sticker] > 0
              CabiePio.unset([:products, :sticker], prod.id) unless raw[:sticker] > 0
            end
            prod.backsync if prod.global?
            known_cities_add prod.place_id
            ProductAssist.otree_job(otree_compare prod, preduct)

            time_now = Time.now.to_f
            if (time_now - prew_time_now > 2)
              prew_time_now = time_now
              out << "§#{ p_index }"
            end
          rescue Exception => e
            out << "§MERRP:ID:[#{ prod.id }] - Error:#{ e }"
          end
        end
        OrderAssist.reset_products_list
      rescue Exception => e
        out << "§MERR:#{ e.inspect }"
      end
    end
  end

  get :export, :provides => :csv do
    products_by_filters(params)

    win_export = params.include? :win
    codes = @products.map(&:place_id).uniq
    @kc_towns = KatoAPI.batch(codes)
    cats = KSM::Category.all.map{ |c| [c.id, c.idname] }.to_h
    fname = 'pio-excel.csv'
    headers['Content-Disposition'] = "attachment; filename=#{ fname }"
    output = ''
    output = "\xEF\xBB\xBF" if win_export
    output << CSV.generate(:col_sep => ';') do |csv|
      csv << %w(id name topcat category type place view price art img corel discount
        bb sticker multi weight height width length windex lotof lotof_mfg tagname sku barcode desc)
      csv << %w(уин название отдел группа тип город вид цена артикул картинка собрание скидка
        склад стикер множитель вес высота ширина длина индекс кратность производство тег индекс штрихкод описание)
      @products.each do |t|
        xt = SL::Product.new t.id
        row_data = [t.id, t.displayname, t.category.category.name, cats[t.category_id], t.name,
          t.hierplace(@kc_towns[t.place_id]&.model), t.look, t.price, t.art, t.sketch_ext, t.fullcorel, t.discount,
          xt.arn, xt.sticker, xt.multi, t.dim_weight, t.dim_height, t.dim_width, t.dim_length, t.windex, t.lotof, t.lotof_mfg, t.tagname, t.autoart, t.autobar, t.desc
        ]
        row_data.map!{ |e| "=\"#{ e.to_s }\"" } if win_export
        csv << row_data
      end
    end
  end
end
