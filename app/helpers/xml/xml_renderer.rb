class Xmle
  UIDZERO = '00000000-0000-0000-0000-000000000000'.freeze
  
  extend Fenix::App::KyotoHelpers
  extend Fenix::App::C1CHelper

  class << self
    def lib_create_doc_xml(root)
      doc = LibXML::XML::Document.new
      doc.encoding = LibXML::XML::Encoding::UTF_8
      doc.root = LibXML::XML::Node.new(root)
      LibXML::XML::Attr.new(doc.root, 'xmlns:V8Exch', 'http://www.1c.ru/V8/1CV8DtUD/')
      LibXML::XML::Attr.new(doc.root, 'xmlns:v8', 'http://v8.1c.ru/data')
      LibXML::XML::Attr.new(doc.root, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
      doc
    end

    def lib_create_node(name, value=nil, type=nil)
      node = LibXML::XML::Node.new(name)
      node.content = value.to_s unless value.nil?
      LibXML::XML::Attr.new(node, 'type', type) unless type.nil?
      node
    end

    def create_doc_xml(root)
      doc = Ox::Document.new
      instruct = Ox::Instruct.new(:xml)
      instruct[:version] = '1.0'
      instruct[:encoding] = 'UTF-8'
      doc << instruct

      top = Ox::Element.new(root)
      top['xmlns:V8Exch'] = 'http://www.1c.ru/V8/1CV8DtUD/'
      top['xmlns:v8'] = 'http://v8.1c.ru/data'
      top['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
      doc << top

      doc
    end

    def create_node(name, value=nil, type=nil)
      node = Ox::Element.new(name)
      node << value.to_s unless value.nil?
      # LibXML::XML::Attr.new(node, 'type', type) unless type.nil?
      node
    end

    def nds18(price)
      much = 18.0
      ((price/(100+much))*much).round(2)
    end

    def customer_order2(order)
      n = wonderbox(:w1c, :number).succ

      doc = create_doc_xml('V8Exch:_1CV8DtUD')
      doc.root << (ex = create_node('V8Exch:Data'))
      ex << edict = create_node('DocumentObject.СчетНаОплатуПокупателю')
      edict << create_node('Ref', UIDZERO)
      edict << create_node('DeletionMark', false)
      edict << create_node('Date', order.created_at.strftime("%FT%T") || Time.now.strftime("%FT%T"))
      edict << create_node('Number', format_num_1c(n))
      edict << create_node('Posted', false)
      edict << create_node('АдресДоставки')
      edict << create_node('СтруктурнаяЕдиница', wonderbox(:edict, :bank))
      edict << create_node('ВалютаДокумента', wonderbox(:edict, :currency))
      edict << create_node('ДоговорКонтрагента', UIDZERO)
      edict << create_node('Комментарий', order.id)
      edict << create_node('Контрагент', UIDZERO)
      edict << create_node('КратностьВзаиморасчетов', 0)
      edict << create_node('КурсВзаиморасчетов', 0)
      edict << create_node('Организация', wonderbox(:edict, :org))
      edict << create_node('Ответственный', wonderbox(:edict, :responsible))
      edict << create_node('Склад', wonderbox(:edict, :warehouse))
      edict << create_node('СуммаВключаетНДС', false)
      edict << create_node('СуммаДокумента', order.total.round(2))
      edict << create_node('ТипЦен', wonderbox(:edict, :pricetype))
      edict << create_node('УчитыватьНДС', true)
      edict << create_node('ОрганизацияПолучатель', wonderbox(:edict, :org))

      edict << (prods = create_node('Товары'))
      
      scs = KSM::Section.all
      habits(scs, :index)
      scs.sort_by{|o|o.index||0}.each do |s|
        s.categories.each do |tab|
          order.by_cat(tab.id).each do |item|
            next if item.ignored
            p = CabiePio.get([:product, :k1c], item.product_id).data
            # next unless p
            a = item.done_amount || item.amount
            prods << row = create_node('Row')
            row << create_node('Номенклатура', p || UIDZERO)
            row << create_node('Цена', item.price)
            row << create_node('Сумма', (item.price*a).round(2))
            row << create_node('СтавкаНДС', 'БезНДС')
            row << create_node('СуммаНДС', 0)
            row << create_node('Количество', a)
          end
        end
      end
      edict << create_node('ВозвратнаяТара')
      edict << create_node('Услуги')

      wonderbox_set(:w1c, { number: n })
      
      # doc.to_s
      Ox.dump doc
    end

  end
end