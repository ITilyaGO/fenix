module Fenix::App::MigrateHelpers
  def stickday_009_up(force: false)
    CabiePio.clear(:stickday, :order) if force
    save_stickday_automatic
  end
end