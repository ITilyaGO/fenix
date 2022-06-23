module Fenix::App::C1CHelper
  def format_num_1c(n)
    'Д' + n.to_s.rjust(10, '0')
  end

  def format_product_1c id
    "#{id}-3000-c055-fefe-502022b00000"
  end

  def format_cat_1c id
    "#{id.rjust(8, '0')}-2000-c055-fefe-502022b00000"
  end

  def check_absent_1c(order)
    absen = []
    order.order_lines.each do |item|
      next if item.ignored
      pro = CabiePio.get([:product, :k1c], item.product_id).data
      absen << item.product_id unless pro
    end
    absen
  end

end