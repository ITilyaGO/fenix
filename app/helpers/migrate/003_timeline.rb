module Fenix::App::MigrateHelpers
  def timeline_up(force: false)
    CabiePio.clear(:timeline, :order) if force
    Timeline.all.each do |t|
      CabiePio.set [:timeline, :order], timeline_order(t.order_id, t.start_at), t.order_id
      CabiePio.set [:orders, :timeline], t.order_id, timeline_id(t.start_at)
    end
  end
end