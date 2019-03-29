class Order < ActiveRecord::Base
  enum status: [ :draft, :anew, :current, :finished, :shipped, :canceled ]
  enum delivery: [ :postage, :roundtrip, :pickup ]
  
  belongs_to :client
  belongs_to :place
  has_many :order_lines
  has_many :order_parts
  has_many :logs
  has_one :timeline

  scope :in_work, -> { where.not(:status => statuses[:draft]) }

  # def self.status_name(status)
  #   case status
  #   when 0
  #     "Unknown"
  #   when 1
  #     "Новый"
  #   when 2
  #     "Подтвержден"
  #   when 3
  #     "Отгружен"
  #   else
  #     "Empty"
  #   end
  # end
  
  
  def self.online_count
    Online::Order.where("status = ?", 1).count
  end
  
  def place_name
    place.nil? ? "" : place.name
  end

  def self.status_for_select
    statuses.map do |type, _|
      [I18n.t("status.#{type}"), type]
    end
  end
  
  def self.delivery_for_select
    deliveries.map do |type, _|
      [I18n.t("delivery.#{type}"), type]
    end
  end
  
  def total_price
    total = 0
    order_lines.each do |ol|
      total += ol.price*ol.amount
    end
    total
  end
  
  def by_cat(id)
    order_lines.joins(product: :category)
      .preload(:product)
      .select("order_lines.*")
      .select('"products"."index" as p_index').select('"categories"."index" as c_index')
      .where('"categories"."category_id" = %s', id)
      .order("c_index, p_index")
  end

  def by_cat?(id)
    order_lines.joins(product: :category)
      .where('"categories"."category_id" = %s', id)
      .any?
  end

  def by_sec?(id)
    v = false
    s = Section.find(id)
    s.categories.each do |cat|
      if by_cat?(cat.id)
        v = true
        break
      end
    end
    v
  end

  def by_section?(id)
    order_lines
      .joins(product: :category)
      .joins(category: :section)
      .where('"categories"."category_id" = %s', id)
      .any?
  end

  def self.iq(id)
    a = id ^ 23081
    v = a.to_s
    if v.size < 2
      v
    else
      v2 = v.chars[1]
      vl = v.chars.last
      v[1] = vl
      v[v.chars.length - 1] = v2
      
      g = "%s%s" % [v[0], v[1..v.length].reverse]
      g
      # "%s%s" % [Random.new.rand(1..9), v]
    end
  end
  
  def self.deiq(id)
    if id.size < 2
      v = id
    else
      g = "%s%s" % [id[0], id[1..id.length].reverse]
      id = g
      v2 = id.chars[1]
      vl = id.chars.last
      id[1] = vl
      id[id.chars.length - 1] = v2
      v = id
    end
    a = v.to_i ^ 23081
    a
  end
  
  def self.shift_32 x, shift_amount
    shift_amount &= 0x1F
    x <<= shift_amount
    x &= 0xFFFFFFFF
    
    if (x & (1<<31)).zero?
     x
    else
     x - 2**32
    end
  end
end
