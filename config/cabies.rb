# Define mutex object for cabinetes
$cabs_locks = { }
Cabie.lock $cabs_locks

Cabie.room :pio, alias: 'pio', path: 'db/cabs', marshal: false, log: true
Cabie.open :pio, :write
Cabie.room :kato, alias: 'isokato', path: 'db/cabs', marshal: true, log: true
Cabie.room :index, alias: 'isokato_index', path: 'db/cabs', log: true
Cabie.open :kato, :write
Cabie.open :index, :write

ALL_CABIES = Cabie::CabieLayer.layz(Cabie.species.keys)
KatoAPI.startup db: CabieKato, index: CabieIndex
at_exit do
  ALL_CABIES.keys.each do |layer|
    Cabie.close layer
  end
end

# # TODO: figure out
# # Define structure of cabinetes

# KCL = {}
# KCL[:main] = { amount_types: [:a1, :a2, :a3] }

KyotoCorp.socket_path = case Padrino.env
when :production
  '/var/run/www/kyotocorp.sock'
when :test
  '/var/run/www/kyotocorp_test.sock'
when :development
  '/Users/aleks/Documents/kyotocorp-server/kyotocorp.sock'
end

KyotoCorp::EasyAccess.config
# class KyotoCorp::EA < KyotoCorp::EasyAccess
# end
class KyotoCorp::CabieIndex < KyotoCorp::EasyAccess
end
class KyotoCorp::Online < KyotoCorp::EasyAccess
end
class KyotoCorp::Pio < KyotoCorp::EasyAccess
end
class KyotoCorp::KAPI < KyotoCorp::EasyAPI
end

# KyotoCorp::EA.config do |c|
#   c.app_name = :dekol_ea
#   c.name = :kato
# end

KyotoCorp::CabieIndex.config do |c|
  c.app_name = :pio_eai
  c.name = :index
end

KyotoCorp::Online.config do |c|
  c.app_name = :pio_cabie_main
  c.name = :main
end

KyotoCorp::Pio.config do |c|
  c.app_name = :pio_ea
  c.name = :pio
end

KyotoCorp::KAPI.config do |c|
  c.app_name = :pio_kapi
  c.isokato = :kato
  c.index = :index
end