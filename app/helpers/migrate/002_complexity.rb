module Fenix::App::MigrateHelpers
  def complexity_up(force: false)
    OrderJobs.complexity_job(force: force)
  end

  def complexity_up_job(force: false)
    $background.in '0s' do
      complexity_up(force:force)
    end
  end

  def complexity_init
    cats = Category.where(category: nil)
    cats.each do |c|
      CabiePio.set [:complexity, :category], c.id, '1:1'
    end
    wonderbox_set(:complexity, { level: 256 })
  end
end