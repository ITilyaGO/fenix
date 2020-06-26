class Product < ActiveRecord::Base
  belongs_to :category
  has_many :variants, -> { order(:name) }, :class_name => "Product", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Product", :foreign_key => "parent_id"

  # def min_order
  #   case category_id
  #   when 15
  #     100
  #   when 16
  #     5
  #   else
  #     10
  #   end
  # end
  
  def displayname
    parent_id ? "#{parent.name} #{name}" : name
  end

  def bump
    0
  end
  
  def p_cat
    category.category.id if !category.category.nil?
  end
  
  def self.sync
    Product.delete_all
    Product.record_timestamps = false
    Online::Product.all.each do |product|
      dup = product.attributes.merge({:id => product.id})
      Product.create(dup)
    end
    Product.record_timestamps = true

    OrderAssist.reset_products_list
  end
end
