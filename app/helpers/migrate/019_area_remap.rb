module Fenix::App::MigrateHelpers
  def m019_area_remap force: nil
    KSI::Area.destroy_all if force
    Product.all.each do |thing|
      area = KSI::Area.find(thing.place_id)
      area = KSI::Area.nest(thing.place_id) unless area.exist?
      area.push thing.id
    end
  end
end