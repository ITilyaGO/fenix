class Category < ActiveRecord::Base
  has_many :subcategories, :class_name => "Category", :foreign_key => "category_id", :counter_cache => true
  has_many :products, -> { where active: true, parent_id: nil }
  has_many :all_products, :class_name => "Product"
  belongs_to :category, :class_name => "Category"
  belongs_to :section

  # attr_accessible :products_count
  # attr_accessor  :nick

  def subs_ordered
    subcategories.order(:index => :asc)
  end

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

  def self.sync
    sections = Category.all.pluck(:id, :section_id).to_h.compact
    sections ||= {18=>1, 19=>2, 20=>3, 21=>4, 22=>4, 23=>5, 24=>1, 26=>4, 61=>1}
    Category.delete_all
    Category.record_timestamps = false
    Online::Category.all.each do |cat|
      dup = cat.attributes.delete_if{|k|k=='pio_id'}.merge({:id => cat.id})
      dup[:section_id] = sections[dup[:id]]
      Category.create(dup)
    end
    Category.record_timestamps = true

    OrderAssist.reset_products_list
  end
end
