class Section < ActiveRecord::Base
  has_many :accounts
  has_many :categories

  attr_accessor :index
end