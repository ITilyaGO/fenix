class Region < ActiveRecord::Base
  belongs_to :manager
  has_many :places

  def manager_name
    manager.nil? ? '' : manager.name
  end
end
