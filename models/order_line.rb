class OrderLine < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  has_many :order_line_comments

  def sattributes
    attributes.map{|k,v|[k.to_sym,v]}.to_h
  end

  def save vld = false
    ksm = KSM::OrderLine.find id
    ksm.fill sattributes.slice(*%i(price amount done_amount ignored)).merge({ merge: true })
    ksm.save

    super vld
  end
end
