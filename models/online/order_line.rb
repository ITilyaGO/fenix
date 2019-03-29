class Online::OrderLine < Online::Base
  self.table_name = 'order_lines'
  belongs_to :order
  belongs_to :product
end