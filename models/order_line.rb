class OrderLine < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  has_many :order_line_comments
  after_save :ksm_apd

  def sattributes
    attributes.map{|k,v|[k.to_sym,v]}.to_h
  end
  
  def ksm_apd
    ksm = KSM::OrderLine.find id
    ksm.fill sattributes.merge({ merge: true })
    ksm.save
  end
end
