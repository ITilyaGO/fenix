# frozen_string_literal: true

module Xmlfr
  Uidzero = '00000000-0000-0000-0000-000000000000'
  Uidone = '00000000-2001-c055-fefe-502022b00000'
  Datezero = '0001-01-01T00:00:00'

  extend Fenix::App::KyotoHelpers
  extend Fenix::App::C1CHelper
  extend self

  def create_doc_xml(root)
    doc = Ox::Document.new
    instruct = Ox::Instruct.new(:xml)
    instruct[:version] = '1.0'
    instruct[:encoding] = 'UTF-8'
    doc << instruct

    top = Ox::Element.new(root)
    top['xmlns:V8Exch'] = 'http://www.1c.ru/V8/1CV8DtUD/'
    top['xmlns:core'] = 'http://v8.1c.ru/data'
    top['xmlns:v8'] = 'http://v8.1c.ru/8.1/data/enterprise/current-config'
    top['xmlns:xs'] = 'http://www.w3.org/2001/XMLSchema'
    top['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
    doc << top

    doc
  end

  def create_node(name, value=nil, type=nil)
    create_plain_node "v8:#{name}", value, ("v8:#{type}" if type)
  end

  def create_plain_node(name, value=nil, type=nil)
    node = Ox::Element.new(name)
    node << value.to_s unless value.nil?
    node['xsi:type'] = type if type
    node
  end

  def replace_node node, name, value
    node.method_missing("v8:#{name}").nodes << value
  end

  def nds18(price)
    much = 18.0
    ((price/(100+much))*much).round(2)
  end

  def customer_order2(order)
    n = wonderbox(:w1c, :number).succ
    tnow = Time.now.strftime("%FT%T")

    doc = create_doc_xml('V8Exch:_1CV8DtUD')
    doc.root << (ex = create_plain_node('V8Exch:Data'))
    
    ex << epro = Ox.load(TML_CAT)
    replace_node epro, 'Description', 'Pio'
    replace_node epro, 'ДатаИзменения', Datezero
    replace_node epro, 'Pio', Uidone
    replace_node epro, 'ParentPio', Uidzero
    
    products = order.order_lines.map(&:product_id).uniq
    ps = Product.find_all(products)
    codes = ps.map(&:place_id).uniq
    kc_towns = KatoAPI.batch(codes)
    cats = ps.map{|p|[p.category_id, p.category.category_id]}.flatten.uniq
    cs = KSM::Category.find_all(cats)
    sects = cs.select(&:top?).map(&:section).uniq(&:id)
    sects.each do |sec|
      ex << epro = Ox.load(TML_CAT)
      replace_node epro, 'Description', sec.name
      replace_node epro, 'ДатаИзменения', Datezero
      replace_node epro, 'Pio', format_cat_1c(sec.id)
      replace_node epro, 'ParentPio', Uidone
    end
    cs.sort_by{|c|c.top? ? 0 : 1}.each do |cat|
      ex << epro = Ox.load(TML_CAT)
      replace_node epro, 'Description', cat.name
      replace_node epro, 'ДатаИзменения', Datezero
      replace_node epro, 'Pio', format_cat_1c(cat.id)
      replace_node epro, 'ParentPio', format_cat_1c(cat.top? ? cat.section_id : cat.category_id)
    end
    ps.each do |product|
      ex << epro = Ox.load(TML_PRODUCT)
      replace_node epro, 'НаименованиеПолное', product.displayname(text: true)
      replace_node epro, 'Description', product.displayname(text: true)
      replace_node epro, 'ДатаИзменения', Datezero
      replace_node epro, 'Артикул', product.art.to_s
      replace_node epro, 'Pio', format_product_1c(product.id)
      replace_node epro, 'ParentPio', format_cat_1c(product.category_id)

      replace_node epro, 'Вес', (product.dim_weight || 0).to_s
      replace_node epro, 'Ширина', (product.dim_width || 0).to_s
      replace_node epro, 'Высота', (product.dim_height || 0).to_s
      replace_node epro, 'Длина', (product.dim_length || 0).to_s
      
      replace_node epro, 'РасшЯрд_Город', kc_towns[product.place_id]&.model.name
      replace_node epro, 'РасшЯрд_ВидТовара', product.look.to_s
      replace_node epro, 'КатегорияНоменклатуры', cs.detect { |c| c.id == product.category_id }&.name.to_s
      replace_node epro, 'Комментарий', product.desc if product.desc
    end

    ex << edict = Ox.load(TML_INVOICE)
    replace_node edict, 'Date', order.created_at.strftime("%FT%T") || tnow
    replace_node edict, 'Number', format_num_1c(n)
    replace_node edict, 'Комментарий', order.id.to_s
    replace_node edict, 'СуммаДокумента', order.total.round(2).to_s

    scs = KSM::Section.all
    # habits(scs, :index)
    scs.sort_by(&:ix).each do |s|
      s.categories.sort_by(&:wfindex).each do |tab|
        order.by_cat(tab.id).sort_by{|a|a.product.cindex}.each do |item|
          next if item.ignored
          a = item.done_amount || item.amount
          item_sum = (item.price*a).round(2)
          edict << row = Ox.load(TML_INVOICE_POS)

          replace_node row, 'Pio', format_product_1c(item.product_id)
          replace_node row, 'Цена', item.price.to_s
          replace_node row, 'Сумма', item_sum.to_s
          replace_node row, 'Всего', item_sum.to_s
          replace_node row, 'Количество', a.to_s
        end
      end
    end
    doc.root << create_plain_node('PredefinedData')

    wonderbox_set(:w1c, { number: n })

    Ox.dump doc
  end

def customer_from_products_list(ps)
    n = wonderbox(:w1c, :number).succ
    tnow = Time.now.strftime("%FT%T")

    doc = create_doc_xml('V8Exch:_1CV8DtUD')
    doc.root << (ex = create_plain_node('V8Exch:Data'))

    ex << epro = Ox.load(TML_CAT)
    replace_node epro, 'Description', 'Pio'
    replace_node epro, 'ДатаИзменения', Datezero
    replace_node epro, 'Pio', Uidone
    replace_node epro, 'ParentPio', Uidzero

    codes = ps.map(&:place_id).uniq
    kc_towns = KatoAPI.batch(codes)
    cats = ps.map{|p|[p.category_id, p.category.category_id]}.flatten.uniq
    cs = KSM::Category.find_all(cats)
    sects = cs.select(&:top?).map(&:section).uniq(&:id)
    sects.each do |sec|
      ex << epro = Ox.load(TML_CAT)
      replace_node epro, 'Description', sec.name
      replace_node epro, 'ДатаИзменения', Datezero
      replace_node epro, 'Pio', format_cat_1c(sec.id)
      replace_node epro, 'ParentPio', Uidone
    end
    cs.sort_by{|c|c.top? ? 0 : 1}.each do |cat|
      ex << epro = Ox.load(TML_CAT)
      replace_node epro, 'Description', cat.name
      replace_node epro, 'ДатаИзменения', Datezero
      replace_node epro, 'Pio', format_cat_1c(cat.id)
      replace_node epro, 'ParentPio', format_cat_1c(cat.top? ? cat.section_id : cat.category_id)
    end
    ps.each do |product|
      ex << epro = Ox.load(TML_PRODUCT)
      replace_node epro, 'НаименованиеПолное', product.displayname(text: true)
      replace_node epro, 'Description', product.displayname(text: true)
      replace_node epro, 'ДатаИзменения', Datezero
      replace_node epro, 'Артикул', product.art.to_s
      replace_node epro, 'Pio', format_product_1c(product.id)
      replace_node epro, 'ParentPio', format_cat_1c(product.category_id || '0000')

      replace_node epro, 'Вес', (product.dim_weight || 0).to_s
      replace_node epro, 'Ширина', (product.dim_width || 0).to_s
      replace_node epro, 'Высота', (product.dim_height || 0).to_s
      replace_node epro, 'Длина', (product.dim_length || 0).to_s

      replace_node epro, 'РасшЯрд_Город', kc_towns[product.place_id]&.model.name || ''
      replace_node epro, 'РасшЯрд_ВидТовара', product.look.to_s
      replace_node epro, 'КатегорияНоменклатуры', cs.detect { |c| c.id == product.category_id }&.name.to_s
      replace_node epro, 'Комментарий', product.desc if product.desc
    end

    ex << edict = Ox.load(TML_INVOICE)
    replace_node edict, 'Date', tnow
    replace_node edict, 'Number', format_num_1c(n)
    replace_node edict, 'Комментарий', ''
    replace_node edict, 'СуммаДокумента', '0'

    scs = KSM::Section.all
    ps.each do |product|
      a = 1
      item_sum = (product.price.to_i || 0).round(2)
      edict << row = Ox.load(TML_INVOICE_POS)

      replace_node row, 'Pio', format_product_1c(product.id)
      replace_node row, 'Цена', product.price.to_s
      replace_node row, 'Сумма', item_sum.to_s
      replace_node row, 'Всего', item_sum.to_s
      replace_node row, 'Количество', a.to_s
    end
    doc.root << create_plain_node('PredefinedData')

    wonderbox_set(:w1c, { number: n })

    Ox.dump doc
  end

end