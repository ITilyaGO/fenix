class Online::Account < Online::Base
  self.table_name = 'accounts'
  has_many :orders
end
