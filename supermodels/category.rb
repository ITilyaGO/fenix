class KSM::Category < Doppel
  PFX = :category

  PROPS = [:name, :sn, :category_id, :section_id, :lotof, :windex, :created_at]
  FPROPS = %i[lotof]
  attr_accessor *PROPS
  
  def category
    KSM::Category.find @category_id
  end

  def section
    KSM::Section.find @section_id
  end

  def subs_ordered
    KSM::Category.all.select{ |a| a.category_id == id }.sort_by(&:wfindex)
  end

  def all_products
    Product.all.select{ |a| a.category_id == id }.sort_by(&:wfindex)
  end

  def top?
    @category_id.nil?
  end

  def wfindex
    @windex || 0
  end

  def display
    return [category.name, name].join(' – ') unless top?
    name
  end

  def idname
    [id, name].join(':')
  end

  def hiername show_sec: false
    na = !top? ? [id, show_sec ? section.name : nil, category.name, name] : [id, show_sec ? section.name : nil, name]
    na.compact.join(':')
  end

  def sequ
    nums = [sn]
    nums.unshift(category.sn) unless top?
    nums.map{|n| "%02i" % n.to_i}.join('.')
  end

  def to_jr
    {
      **to_r,
      name: display,
      windex: wfindex
    }
  end

  def clear_formize form
    FPROPS.each do |prop|
      form[prop] = nil if pe = form[prop]&.empty?
      instance_variable_set("@#{prop}", nil) if pe
    end

    formiz form
  end

  def backsync
    oc = Online::Category.find_by(pio_id: @category_id)
    return if !oc && !top?
    op = Online::Category.find_by(pio_id: @id) || Online::Category.new({ pio_id: @id })
    op.name = @name
    op.category_id = oc&.id
    op.index = @windex
    op.save

    stompsync rescue nil
  end

  def stompsync
    client = Stomp::Client.open 'guest', 'guest', "localhost", 61613
    client.publish("/topic/web:category:lotof", Marshal.dump({ id: @id, min: @lotof }), { "priority" => 2 })
    client.close
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

    def schema
      {
        sn: [:to_i],
        windex: [:to_i],
        lotof: [:to_i]
      }
    end

    def toplevel
      all.select(&:top?)
    end
  end
end

KSM::Category.config do |c|
  c.gen = [:hex, 2]
end