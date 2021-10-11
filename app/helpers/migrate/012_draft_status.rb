module Fenix::App::MigrateHelpers
  def draft_status_012_up(force: false)
    ru = {
      1 => 'Клиент отвечает',
      2 => 'Счёт отправлен',
      3 => 'Предоплата пришла',
      4 => 'Макеты делают'
    }
    wonderbox_set(:draftstatus_ru, ru)
  end
end