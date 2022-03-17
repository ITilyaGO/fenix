class KSM::Category < Doppel
  PFX = :category

  PROPS = [:name, :sn, :category_id, :section_id, :created_at]
  attr_accessor *PROPS
  
  def category
    KSM::Category.find @category_id
  end

  def section
    KSM::Section.find @section_id
  end

  def subs_ordered
    KSM::Category.all.select{ |a| a.category_id == id }
  end

  def all_products
    Product.all.select{ |a| a.category_id == id }
  end

  def top?
    @category_id.nil?
  end

  def display
    return [category.name, name].join(' – ') unless top?
    name
  end

  def hiername
    na = !top? ? [id, section.name, category.name, name] : [id, section.name, name]
    na.join(':')
  end

  def sequ
    nums = [sn]
    nums.unshift(category.sn) unless top?
    nums.map{|n| "%02i" % n.to_i}.join('.')
  end

  def to_jr
    {
      **to_r,
      name: display
    }
  end

  # def updated_at
  #   @updated_at || Date.new(1970,1,1)
  # end

  # def saved_by account
  #   @dates ||= []
  #   @created_at ||= Time.now
  #   @updated_at = Time.now
  #   @users ||= []
  #   @users << account.id unless @users.include?(account.id)
  #   @history ||= {}
  #   @history[Time.now] = account.id
  #   save
  # end
  
  class << self
    def nest
      e = super
      e.fill(created_at: Time.now, name: 'Unknown', merge: true)
      e
    end

    def toplevel
      all.select(&:top?)
    end
  end
end

KSM::Category.config do |c|
  c.gen = [:hex, 2]
end