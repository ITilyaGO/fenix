class OrderLine < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  has_many :order_line_comments
end
