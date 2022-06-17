module Fenix::App::MigrateHelpers
  def m015_ru_isokato_up force: nil
    
    id = 'RU'
    town_name = 'Россия'
    # CabieKato.set [Kato::PFXR, Kato::PFX[:town]], id, { name: town_name }
    CabieKato.set [Kato::PFXR, Kato::PFX[:country]], id, { name: town_name }
    CabieKato.set [Kato::PFXR, Kato::PFX[:all]], id, { name: town_name }
    # CabieKato.set [:p, :custom], id, id
    CabieIndex.set [:full], town_name.downcase, id
    CabieIndex.set [:short], town_name.downcase, id

  end
end