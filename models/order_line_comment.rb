class OrderLineComment < ActiveRecord::Base
  belongs_to :order
  belongs_to :account
end
