module Fenix::App::C1CHelper
  def format_num_1c(n)
    'Д' + n.to_s.rjust(10, '0')
  end

  def check_absent_1c(order)
    absen = []
    order.order_lines.each do |item|
      next if item.ignored
      p = CabiePio.get([:product, :k1c], item.product_id).data
      absen << item.product_id unless p
    end
    absen
  end

end