class KSM::OrderLine < Doppel
  PFX = :orderline

  PROPS = [:description, :order_id, :product_id, :price, :amount, :done_amount, :ignored, :created_at]
  SVSPROPS = [:created_at, :updated_at, :dates, :users, :history]
  PROPS += SVSPROPS
  attr_accessor *PROPS
  attr_accessor :xt

  def updated_at
    @updated_at || Date.new(1970,1,1)
  end

  def product
    Product.find product_id
  end

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

  def nest value = nextseed
    self.new id: value
  end

  def nextseed
    cs = LAYER.get(%i[m wonderbox] << PFX, :seed).data || 0
    cs += 1
    LAYER.set %i[m wonderbox] << PFX, :seed, cs
    cs
  end
  
  class << self
    # def nest
    #   e = super
    #   e.fill(created_at: Time.now, name: 'Unknown', merge: true)
    #   e
    # end

    # def schema
    #   {
    #     price: [:to_f]
    #   }
    # end
  end
end