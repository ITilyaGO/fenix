module Fenix::App::MigrateHelpers
  def m018_orderlines_remove_up force: nil
    KSM::OrderLine.all.each do |ksmol|
      ksmol.remove unless OrderLine.exists?(ksmol.id)
    end
  end
end