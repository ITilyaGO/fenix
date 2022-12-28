class Order < ActiveRecord::Base
  enum status: [ :draft, :anew, :current, :finished, :shipped, :canceled ]
  enum delivery: [ :postage, :roundtrip, :pickup, :vernissage ]
  
  belongs_to :client
  belongs_to :place
  has_many :order_lines_ar, class_name: 'OrderLine'
  has_many :order_parts
  has_many :logs
  has_one :timeline

  scope :in_work, -> { where.not(:status => statuses[:draft]) }
  scope :fin, -> { where(:status => statuses[:finished]) }

  after_save :ksm_apd

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
    Online::Order.fresh.count
  end
  
  def place_name
    place.nil? ? "" : place.name
  end

  def self.status_for_select
    statuses.map do |type, _|
      [I18n.t("status.#{type}"), type]
    end
  end
  
  def total_price
    total = 0
    order_lines.each do |ol|
      total += ol.price*ol.amount
    end
    total
  end

  # TODO: unused
  def order_lines_ids
    KSM::Order.find(id).lines
  end

  def order_lines
    # oids = order_lines_ar.ids
    KSM::OrderLine.find_all(KSM::Order.find(id).lines).reject(&:del)
  end
  
  def ksm_apd
    kso = KSM::Order.new(attributes)
    kso.lines = order_lines_ar_ids
    kso.save
  end

  def by_cat(id)
    order_lines.select{ |ol| Product.find(ol.product_id).category.category_id == id }
    # order_lines.joins(product: :category)
    #   .preload(:product)
    #   .select("order_lines.*")
    #   .select('"products"."index" as p_index').select('"categories"."index" as c_index')
    #   .where('"categories"."category_id" = %s', id)
    #   .order("c_index, p_index")
  end

  def by_cat?(id)
    order_lines.select{ |ol| Product.find(ol.product_id).category.category_id == id }.any?
    # order_lines.joins(product: :category)
    #   .where('"categories"."category_id" = %s', id)
    #   .any?
  end

  def by_sec?(id)
    v = false
    s = KSM::Section.find(id)
    s.categories.each do |cat|
      if by_cat?(cat.id)
        v = true
        break
      end
    end
    v
    # v = false
    # s = Section.find(id)
    # s.categories.each do |cat|
    #   if by_cat?(cat.id)
    #     v = true
    #     break
    #   end
    # end
    # v
  end

  def sumsec id, which = :total
    s = KSM::Section.find(id)
    s.categories.sum do |cat|
      by_cat(cat.id).sum(&which)
    end
  end

  def sumsecd id, which = :total, deli = nil
    return 0 unless deli || deli == delivery
    s = KSM::Section.find(id)
    s.categories.sum do |cat|
      by_cat(cat.id).sum(&which)
    end
  end

  def by_section?(id)
    order_lines
      .joins(product: :category)
      .joins(category: :section)
      .where('"categories"."category_id" = %s', id)
      .any?
  end

  def actualize
    OrderAssist.calc_complexity_for self
    OrderAssist.calc_stickers_for self
  end

  def self.holder(id = 0)
    Order.new({id: id, status: 5, created_at: Time.now, client: Client.new})
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
