module Fenix::App::MigrateHelpers
  def draft_status_012_up(force: false)
    ru = {
      1 => 'Клиент молчит',
      2 => 'Выслан счёт',
      3 => 'Пришла предоплата',
      4 => 'Делают макеты'
    }
    wonderbox_set(:draftstatus_ru, ru)
  end
end