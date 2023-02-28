module Fenix::App::MigrateHelpers
  def m020_otree_render force: nil
    known_cities.keys.each do |place|
      otree_render place
    end
  end
end