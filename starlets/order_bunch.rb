class OrderBunch < Order
  def by_cat(id)
    pmtx = OrderAssist.products_hash
    cmtx = OrderAssist.category_matrix
    alca = OrderAssist.all_catagories
    pids = order_lines.map(&:product_id)
    # pro = Product.all_keys(pids)
    pro = Product.where(id: pids)
    order_lines.select{ |ol| cmtx[pmtx[ol.product_id]] == id }.sort_by do |ol|
      [alca.detect{ |a| pmtx[ol.product_id] == a.id }&.index || 0, pro.detect{|a| ol.product_id == a.id }&.index || 0]
    end
  end

  def by_cat?(id)
    by_cat(id).any?
  end
end