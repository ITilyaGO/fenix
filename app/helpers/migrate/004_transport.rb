module Fenix::App::MigrateHelpers
  def transport_up(force: false)
    CabiePio.clear(:m, :clients, :transport) if force
    cl = CabiePio.folder(:m, :migrate, :transport).flat
    cl.each do |k, v|
      CabiePio.set [:m, :clients, :transport], k, v
    end
  end

  def transport_down(force: false)
    CabiePio.clear(:m, :clients, :transport) if force
    CabiePio.clear(:m, :migrate, :transport) if force
  end

  def transport_preview
    sql_avail_shipping
  end
end