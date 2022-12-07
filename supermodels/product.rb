class Product < Doppel
  PFX = :thing

  PROPS = %i[name sn category_id place_id sketch_id company_id origin barcode price sku art g bbid
    discount lotof lotof_mfg desc dim_weight dim_height dim_length dim_width look corel windex tagname
  ]
  FPROPS = %i[art discount lotof lotof_mfg desc dim_weight dim_height dim_length dim_width look corel]
  SVSPROPS = %i[created_at updated_at ignored dates users history settings]
  PROPS += SVSPROPS
  attr_accessor *PROPS
  attr_accessor :xt

  def group?
    @g
  end

  def global?
    place_id == 'RU'
  end

  def wfindex
    (@windex || :aaaaaaaa).to_s.rjust(8,"0")
    displayname(text: true).downcase
  end

  def cindex
    [@ignored == 1 ? 1 : 0, category.wfindex, wfindex, displayname(text: true)].join
  end

  def displayname text: false
    nip = settings&.fetch(:ni, 0)
    pip = settings&.fetch(:pi, 0)
    city = OrderAssist.known_cities[@place_id]&.model&.name
    a = [name, city, look]
    a = [name, look, city] if nip == 1
    a = [name, look] if pip == 1
    a.unshift '☠️' if @ignored == 1 && !text
    a.compact.join(' ')
  end

  def simplename
    [name, look].compact.join(' ')
  end

  def fullcorel
    [OrderAssist.cache_corel_root, corel].join
  end

  def category
    KSM::Category.find @category_id
  end

  def updated_at
    @updated_at || Date.new(1970,1,1)
  end

  def autoart
    nums = ["%02i" % category.section.sn, category.sequ, "%06i" % sn].join('.') rescue ''
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

  def hierplace kato
    [place_id, kato].join(':')
  end

  def to_jr
    {
      name: displayname
    }.merge to_r.slice(*%i[id price category_id place_id price art])
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

  def clear_formize form
    @settings ||= {}
    ht = { :nit => :ni, :pit => :pi }
    ht.values.each do |v|
      settings.store(v, form[ht.key(v)].send(*self.class.schema[v]))
    end
    FPROPS.each do |prop|
      form[prop] = nil if pe = form[prop]&.empty?
      instance_variable_set("@#{prop}", nil) if pe
    end

    formiz form
  end
  
  def backsync
    oc = Online::Category.find_by(pio_id: @category_id)
    return false unless oc
    op = Online::Product.find_by(pio_id: @id) || Online::Product.new({ pio_id: @id })
    op.price = @price
    op.name = simplename
    op.active = @ignored != 1
    op.category_id = oc.id
    op.height = @dim_height
    op.tagname = @tagname
    op.index = @windex
    op.save

    stompsync rescue nil
  end

  def stompsync
    client = Stomp::Client.open Stomp::DETAILS
    client.publish("/topic/web:product:lotof", Marshal.dump({ id: @id, min: @lotof }), { "priority" => 2 })
    client.close
  end

  class << self
    def nest
      e = super
      e.fill(created_at: Time.now, name: 'Unknown', merge: true)
      e
    end

    def schema
      {
        price: [:to_i],
        weight: [:to_i],
        height: [:to_i],
        sn: [:to_i],
        ni: [:to_i],
        pi: [:to_i],
        ignored: [:to_i],
        discount: [:to_i],
        lotof: [:to_i],
        lotof_mfg: [:to_i]
      }
    end

    def pluck *opts
      []
    end
  end
end