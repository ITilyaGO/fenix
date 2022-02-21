class Product < Doppel
  PFX = :thing

  PROPS = [:name, :sn, :category_id, :place_id, :sketch_id, :company_id, :barcode, :price, :sku, :art, :created_at, :g, :bbid]
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
    KSM::Category.find @category_id
  end

  def updated_at
    @updated_at || Date.new(1970,1,1)
  end

  def autoart
    nums = ["%02i" % category.section.sn.to_i, category.sequ, "%06i" % sn.to_i].join('.')
  end

  def autobar
    "%012i" % autoart.gsub(/\./, '').to_i
  end

  def sketch_ext
    "#{autoart}.jpg"
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

    def pluck *opts
      []
    end
  end
end