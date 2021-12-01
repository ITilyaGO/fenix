class KSM::Thing < Doppel
  PFX = :thing

  PROPS = [:name, :category_id, :place_id, :sketch_id, :company_id, :barcode, :price, :sku, :art, :created_at, :g, :bbid]
  SVSPROPS = [:created_at, :updated_at, :dates, :users, :history]
  PROPS += SVSPROPS
  attr_accessor *PROPS
  attr_accessor :xt

  def group?
    @g
  end

  def displayname
    @name
  end

  def category
    Category.find @category_id
  end

  def updated_at
    @updated_at || Date.new(1970,1,1)
  end

  def n1c
    xt ||= {}
    xt[:n1c]
  end

  def saved_by account
    @dates ||= []
    @created_at ||= Time.now
    @updated_at = Time.now
    @users ||= []
    @users << account.id unless @users.include?(account.id)
    @history ||= {}
    @history[Time.now] = account.id
    save
  end
  
  class << self
    def nest
      e = super
      e.fill(created_at: Time.now, name: 'Unknown', merge: true)
      e
    end

    def schema
      {
        price: [:to_f]
      }
    end
  end
end