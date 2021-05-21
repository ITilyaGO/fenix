module Fenix::App::MigrateHelpers
  def stock_006_up(force: false)
    OrderJobs.stock_job(force: force)
    
  end
end