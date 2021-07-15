module Fenix::App::MigrateHelpers
  def order_status_010_up(force: false)
    KSM::OrderStatus.destroy_all if force
    orders = Order.all
    orders.each do |order|
      o_status = KSM::OrderStatus.find(order.id)
      o_status.setg(order.status.to_sym)
      order.order_parts.each do |op|
        o_status.sets(op.section_id, op.state.to_sym)
      end
      o_status.save
    end
  end
end