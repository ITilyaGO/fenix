class OrderBunch < Order
  attr_accessor :order_lines

  def initialize(*opts)
    super
    @order_lines ||= []
    self
  end

  def by_cat(id)
    pmtx = OrderAssist.products_hash
    cmtx = OrderAssist.category_matrix
    alca = OrderAssist.all_catagories
    pids = order_lines.map(&:product_id)
    pro = Product.find_all(pids)
    # pro = Product.where(id: pids)
    order_lines.select{ |ol| cmtx[pmtx[ol.product_id]] == id }.sort_by do |ol|
      # [alca.detect{ |a| pmtx[ol.product_id] == a.id }&.cindex, pro.detect{|a| ol.product_id == a.id }&.cindex]
      pro.detect{|a| ol.product_id == a.id }&.cindex
    end
  end

  def by_cat?(id)
    by_cat(id).any?
  end
end