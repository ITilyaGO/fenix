class KSM::Section < Doppel
  PFX = :section

  PROPS = [:name, :sn, :ix, :created_at]
  attr_accessor *PROPS
  attr_accessor :index

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
  
  def categories
    KSM::Category.all.select{|a| a.category_id.nil? && a.section_id == id}
  end

  class << self
    def nest
      e = super
      e.fill(created_at: Time.now, name: 'Unknown', merge: true)
      e
    end
  end
end

KSM::Section.config do |c|
  c.gen = [:hex, 2]
end