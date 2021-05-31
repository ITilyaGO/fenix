module Fenix::App::MigrateHelpers
  def create_archetypes_008_up(force: false)
    KSM::Archetype.destroy_all if force
    create_absent_archetypes
  end
end