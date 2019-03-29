class CreateManagersAndRegions < ActiveRecord::Migration
  class Region < ActiveRecord::Base
    # empty guard class, guaranteed to have basic AR behavior
  end

  def self.up
    create_table :managers do |t|
      t.string :name
      t.timestamps
    end
    create_table :regions do |t|
      t.string :code
      t.string :name
      t.integer :manager_id
      t.timestamps
    end
    add_column :places, :region_id, :integer

    # Seed regions data
    Region.create :code => '76', :name => 'Ярославская область'
    Region.create :code => '22', :name => 'Алтайский край'
    Region.create :code => '28', :name => 'Амурская область'
    Region.create :code => '29', :name => 'Архангельская область'
    Region.create :code => '30', :name => 'Астраханская область'
    Region.create :code => '31', :name => 'Белгородская область'
    Region.create :code => '32', :name => 'Брянская область'
    Region.create :code => '33', :name => 'Владимирская область'
    Region.create :code => '34', :name => 'Волгоградская область'
    Region.create :code => '35', :name => 'Вологодская область'
    Region.create :code => '36', :name => 'Воронежская область'
    Region.create :code => '77', :name => 'Москва'
    Region.create :code => '79', :name => 'Еврейская автономная область'
    Region.create :code => '75', :name => 'Забайкальский край'
    Region.create :code => '37', :name => 'Ивановская область'
    Region.create :code => '99', :name => 'Иные территории, включая город и космодром Байконур'
    Region.create :code => '38', :name => 'Иркутская область'
    Region.create :code => '07', :name => 'Кабардино-Балкарская Республика'
    Region.create :code => '39', :name => 'Калининградская область'
    Region.create :code => '40', :name => 'Калужская область'
    Region.create :code => '41', :name => 'Камчатский край'
    Region.create :code => '09', :name => 'Карачаево-Черкесская Республика'
    Region.create :code => '42', :name => 'Кемеровская область'
    Region.create :code => '43', :name => 'Кировская область'
    Region.create :code => '44', :name => 'Костромская область'
    Region.create :code => '23', :name => 'Краснодарский край'
    Region.create :code => '24', :name => 'Красноярский край'
    Region.create :code => '45', :name => 'Курганская область'
    Region.create :code => '46', :name => 'Курская область'
    Region.create :code => '47', :name => 'Ленинградская область'
    Region.create :code => '48', :name => 'Липецкая область'
    Region.create :code => '49', :name => 'Магаданская область'
    Region.create :code => '50', :name => 'Московская область'
    Region.create :code => '51', :name => 'Мурманская область'
    Region.create :code => '83', :name => 'Ненецкий автономный округ'
    Region.create :code => '52', :name => 'Нижегородская область'
    Region.create :code => '53', :name => 'Новгородская область'
    Region.create :code => '54', :name => 'Новосибирская область'
    Region.create :code => '55', :name => 'Омская область'
    Region.create :code => '56', :name => 'Оренбургская область'
    Region.create :code => '57', :name => 'Орловская область'
    Region.create :code => '58', :name => 'Пензенская область'
    Region.create :code => '59', :name => 'Пермский край'
    Region.create :code => '25', :name => 'Приморский край'
    Region.create :code => '60', :name => 'Псковская область'
    Region.create :code => '01', :name => 'Республика Адыгея'
    Region.create :code => '04', :name => 'Республика Алтай'
    Region.create :code => '02', :name => 'Республика Башкортостан'
    Region.create :code => '03', :name => 'Республика Бурятия'
    Region.create :code => '05', :name => 'Республика Дагестан'
    Region.create :code => '06', :name => 'Республика Ингушетия'
    Region.create :code => '08', :name => 'Республика Калмыкия'
    Region.create :code => '10', :name => 'Республика Карелия'
    Region.create :code => '11', :name => 'Республика Коми'
    Region.create :code => '91', :name => 'Республика Крым'
    Region.create :code => '12', :name => 'Республика Марий Эл'
    Region.create :code => '13', :name => 'Республика Мордовия'
    Region.create :code => '14', :name => 'Республика Саха (Якутия)'
    Region.create :code => '15', :name => 'Республика Северная Осетия - Алания'
    Region.create :code => '16', :name => 'Республика Татарстан'
    Region.create :code => '17', :name => 'Республика Тыва'
    Region.create :code => '19', :name => 'Республика Хакасия'
    Region.create :code => '61', :name => 'Ростовская область'
    Region.create :code => '62', :name => 'Рязанская область'
    Region.create :code => '63', :name => 'Самарская область'
    Region.create :code => '78', :name => 'Санкт-Петербург'
    Region.create :code => '64', :name => 'Саратовская область'
    Region.create :code => '65', :name => 'Сахалинская область'
    Region.create :code => '66', :name => 'Свердловская область'
    Region.create :code => '92', :name => 'Севастополь'
    Region.create :code => '67', :name => 'Смоленская область'
    Region.create :code => '26', :name => 'Ставропольский край'
    Region.create :code => '68', :name => 'Тамбовская область'
    Region.create :code => '69', :name => 'Тверская область'
    Region.create :code => '70', :name => 'Томская область'
    Region.create :code => '71', :name => 'Тульская область'
    Region.create :code => '72', :name => 'Тюменская область'
    Region.create :code => '18', :name => 'Удмуртская Республика'
    Region.create :code => '73', :name => 'Ульяновская область'
    Region.create :code => '27', :name => 'Хабаровский край'
    Region.create :code => '86', :name => 'Ханты-Мансийский автономный округ - Югра'
    Region.create :code => '74', :name => 'Челябинская область'
    Region.create :code => '20', :name => 'Чеченская Республика'
    Region.create :code => '21', :name => 'Чувашская Республика - Чувашия'
    Region.create :code => '87', :name => 'Чукотский автономный округ'
    Region.create :code => '89', :name => 'Ямало-Ненецкий автономный округ'
  end

  def self.down
    drop_table :managers
    drop_table :regions
    remove_column :places, :region_id
  end
end
