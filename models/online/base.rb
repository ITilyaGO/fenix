class Online::Base < ActiveRecord::Base
  conf = Padrino.env == :production ? :online : :online_dev
  establish_connection(ActiveRecord::Base.configurations[conf])
  self.abstract_class = true
end
