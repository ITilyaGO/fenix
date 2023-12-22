module Json1CAssist

  UIDONE = '00000000-2001-c055-fefe-502022b00000'
  EXPORT_VERSION = 1

  extend Fenix::App::C1CHelper
  extend Fenix::App::PictureHelper
  extend self
  
  def products_to_json(products)
    json_data = get_default_json_struct

    json_data['Номенклатура'] = products_to_json_obj(products)

    JSON.generate(json_data)
  end

  def order_to_json(order)
    json_data = get_default_json_struct(order)

    product_ids = order.order_lines.map(&:product_id).uniq
    products = Product.find_all(product_ids)

    json_data['Номенклатура'] = products_to_json_obj(products)
    json_data['ЗаказКлиента']['Товары'] = order_lines_to_json_obj(order)

    JSON.generate(json_data)
  end


  def get_default_json_struct(order = nil)
    json_data = {
      'Version' => EXPORT_VERSION,
      'ГруппаНоменклатуры' => get_categories_json_obj,
      'Номенклатура' => []
    }

    json_data['ЗаказКлиента'] = {
      'Дата' => order.created_at.iso8601,
      'Номер' => order.id.to_s,
      'СуммаЗаказа' => order.total.round(2)&.to_f || 0,
      'Товары' => []
    } if order

    json_data
  end

  def get_categories_json_obj
    json_cats = []
    cs = KSM::Category.all
    sects = cs.select(&:top?).map(&:section).uniq(&:id)
    sects.each do |sec|
      json_cats << {
        'Наименование' => sec.name,
        'ProductPioId' => format_cat_1c(sec.id),
        'CategoryPioId' => UIDONE
      }
    end

    cs.sort_by{ |c| c.top? ? 0 : 1 }.each do |cat|
      json_cats << {
        'Наименование' => cat.name,
        'ProductPioId' => format_cat_1c(cat.id),
        'CategoryPioId' => format_cat_1c(cat.top? ? cat.section_id : cat.category_id)
      }
    end
    json_cats
  end

  def products_to_json_obj(products)
    codes = products.map(&:place_id).uniq
    kc_towns = KatoAPI.batch(codes)
    json_products = []

    products.each do |product|
      image_base64 = product_to_base64_image(product)

      json_products << {
        'Наименование' => product.displayname(text: true),
        'Название' => product.name,
        'Город' => kc_towns[product.place_id]&.model.name,
        'Вид' => product.look.to_s,
        'Артикул' => product.art.to_s,
        'Вес' => (product.dim_weight&.to_f || 0),
        'Высота' => (product.dim_height&.to_f || 0),
        'Ширина' => (product.dim_width&.to_f || 0),
        'Длина' => (product.dim_length&.to_f || 0),
        'Описание' => product.desc || '',
        'Кратность' => product.lotof&.to_i || 1,
        'ProductPioId' => format_product_1c(product.id),
        'CategoryPioId' => format_cat_1c(product.category_id),
        'Image' => image_base64 || ''
      }
    end
    json_products
  end

  def order_lines_to_json_obj(order)
    json_orderlines = []
    scs = KSM::Section.all
    scs.sort_by(&:ix).each do |s|
      s.categories.sort_by(&:wfindex).each do |tab|
        order.by_cat(tab.id).sort_by{ |a| a.product.cindex }.each do |item|
          next if item.ignored
          a = item.done_amount || item.amount
          item_sum = (item.price*a).round(2)

          json_orderlines << {
            'ProductPioId' => format_product_1c(item.product_id),
            'Цена' => item.price,
            'Сумма' => item_sum,
            'Количество' => a
          }
        end
      end
    end
    json_orderlines
  end

  def product_to_base64_image(product)
    if product.picname
      image_path = image_path_from_product(product)
      image_path ? file_to_base64(image_path) : ''
    else
      ''
    end
  end

  def image_path_from_product(product)
    product_pic_file(product.picname, :m)
  end

  def file_to_base64(path)
    file_bin = File.binread(path)
    Base64.strict_encode64(file_bin)
  end
end
