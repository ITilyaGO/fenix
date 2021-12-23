module Fenix::App::MigrateHelpers
  def products_to_things_013_up force: nil
    products = Product.all
    KSM::Thing.destroy_all if force
    backorder = []
    products.each do |p|
      thing = KSM::Thing.nest
      thing.name = p.name
      thing.category_id = p.category_id
      thing.place_id = 'RU-YAR-ARO'
      thing.art = p.des
      thing.price = p.price
      thing.saved_by @current_account

      backorder << thing.id
    end
    wonderbox_set(:things_by_date, backorder.pop(50))
  end
end