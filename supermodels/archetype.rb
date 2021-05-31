class KSM::Archetype < Doppel
  PFX = :archetype

  PROPS = [:name, :category_id, :created_at, :g]
  attr_accessor *PROPS

  def group?
    @g
  end
  
  class << self
    def nest
      e = super
      e.fill(created_at: Time.now, name: 'Unknown', merge: true)
      e
    end
  end
end

KSM::Archetype.config do |c|
  c.gen = [:hex, 2]
end