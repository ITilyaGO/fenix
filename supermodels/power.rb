class KSM::Power < Doppel
  PFX = :power

  PROPS = [:name, :email, :auth, :created_at]
  attr_accessor *PROPS

  def self.find_by_name str
    self.all.detect { |a| a.name == str }
  end
end