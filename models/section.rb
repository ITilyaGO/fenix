class Section < ActiveRecord::Base
  has_many :accounts
  has_many :categories
end