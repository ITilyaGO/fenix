class Online::Product < Online::Base
  self.table_name = 'products'
  belongs_to :category
end
