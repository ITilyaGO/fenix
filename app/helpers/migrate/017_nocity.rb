module Fenix::App::MigrateHelpers
  def m017_nocity_up force: nil
    Product.all.select(&:global?).each do |p|
      next if p.settings&.fetch(:pi, nil) == 1
      p.settings ||= {}
      p.settings.store(:pi, 1)
      p.save
    end
  end
end