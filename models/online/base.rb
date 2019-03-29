class Online::Base < ActiveRecord::Base
  establish_connection(ActiveRecord::Base.configurations[:online])
  self.abstract_class = true
end
