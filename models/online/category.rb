class Online::Category < Online::Base
  self.table_name = 'categories'
  has_many :subcategories, :class_name => "Category", :foreign_key => "category_id", :counter_cache => true
  has_many :products, -> { where active: true }
  belongs_to :category, :class_name => "Category"
  
  # attr_accessible :products_count
  # attr_accessor  :nick
  
  def pro_count
    products.count
    # products.where(active: true).size
  end

  def sub_pro_count(id)
    subcategories.find(id).products.count
  end

  def is_sub_alone?
    subcategories.where(:products_count => 0).any?
  end

  def is_sub?
    b = subcategories.map { |s| s.pro_count }
    b.delete 0
    b.size == 1
  end

  def f_sub
    subcategories.first
    # subcategories.select(:id, :name).includes(:products).where(products: { :active => true }).first
  end

  def self.cats_with_products
    Category.joins(:products).group("categories.id").ids
  end

  def self.cats_subs
    subs = Category.select(:id, :category_id).joins(:products).group("categories.id").where.not(category: nil)
    grouped = subs.group_by { |g| g.category_id }
    h = { }
    grouped.map {|k,v| h[k] = v.first if v.size == 1 }
    h
  end
  
end